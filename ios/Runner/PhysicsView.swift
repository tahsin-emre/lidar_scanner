//
//  PhysicsView.swift
//  Runner
//

import Foundation
import ARKit
import SceneKit
import SceneKit.ModelIO

// Extension for SCNVector3 to support multiplication with a Float
extension SCNVector3 {
    static func * (vector: SCNVector3, scalar: Float) -> SCNVector3 {
        return SCNVector3(vector.x * scalar, vector.y * scalar, vector.z * scalar)
    }
    static func * (scalar: Float, vector: SCNVector3) -> SCNVector3 {
        return SCNVector3(vector.x * scalar, vector.y * scalar, vector.z * scalar)
    }
}

/// A view that handles physics simulation with LiDAR-scanned meshes
class PhysicsView: NSObject, FlutterPlatformView, ARSCNViewDelegate {
    // MARK: - Properties
    private var arView: ARSCNView!
    private let session = ARSession()
    private var configuration = ARWorldTrackingConfiguration()
    
    private var physicsScene: SCNPhysicsWorld {
        return arView.scene.physicsWorld
    }
    
    private var scannedNode: SCNNode?
    private var physicsObjects = [String: SCNNode]()
    private var lastFrameTime: TimeInterval = 0
    private var frameCount = 0
    private var currentFps: Double = 0
    
    // Physics configurations
    private var gravity: Float = -9.8
    private var defaultFriction: CGFloat = 0.5
    private var defaultRestitution: CGFloat = 0.4
    
    // Visual debugging properties
    private var showDebugVisualization: Bool = false
    
    // MARK: - Initialization
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        super.init()
        
        print("PhysicsView: initializing with viewId \(viewId)")
        
        // Set up AR view
        arView = ARSCNView(frame: frame)
        arView.delegate = self
        arView.session = session
        arView.autoenablesDefaultLighting = true
        arView.automaticallyUpdatesLighting = true
        
        // Configure physics debug visualization (if needed)
        if let args = args as? [String: Any],
           let initialConfig = args["initialConfiguration"] as? [String: Any] {
            if let enableDebug = initialConfig["enableDebugVisualization"] as? Bool, enableDebug {
                showDebugVisualization = enableDebug
                arView.debugOptions = [.showPhysicsShapes]
            } else {
                // Ensure debug visualization is disabled by default
                arView.debugOptions = []
            }
        } else {
            // Ensure debug visualization is disabled by default
            arView.debugOptions = []
        }
        
        // Configure physics world
        configurePhysicsWorld()
        
        // Set up frame timing for FPS calculation
        setupFrameTiming()
    }
    
    // MARK: - Public methods
    
    /// Returns the Flutter platform view
    func view() -> UIView {
        return arView
    }
    
    /// Initialize physics with a scanned mesh model
    func initializePhysics(scanPath: String) {
        print("PhysicsView: initializing physics with scan path \(scanPath)")
        
        // Load the 3D model from file
        guard let url = URL(string: scanPath) else {
            print("Error: Invalid scan path URL")
            return
        }
        
        print("PhysicsView: loading model from \(url)")
        
        // Create a static physics body from the mesh
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Load asset with adjusted options for better physics
                let asset = MDLAsset(url: url)
                
                // Convert MDLAsset to SCNScene with proper options
                let scene = SCNScene(mdlAsset: asset)
                
                // Create a node for the scanned model with proper positioning
                let scannedNode = SCNNode()
                
                // Add all nodes from the scene to our container node with proper physics
                for child in scene.rootNode.childNodes {
                    // Create a static physics body for each mesh part
                    if let geometry = child.geometry {
                        // Set material properties for better visualization
                        let material = SCNMaterial()
                        material.diffuse.contents = UIColor.lightGray.withAlphaComponent(0.8)
                        material.isDoubleSided = true
                        geometry.materials = [material]
                        
                        // Create physics shape with concave mesh for accurate collision
                        let physicsShape = SCNPhysicsShape(
                            geometry: geometry,
                            options: [
                                SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron,
                                SCNPhysicsShape.Option.keepAsCompound: true,
                                SCNPhysicsShape.Option.collisionMargin: 0.01
                            ]
                        )
                        
                        // Use Kinematic body for user-adjustable environment mesh
                        child.physicsBody = SCNPhysicsBody(type: .kinematic, shape: physicsShape)
                        child.physicsBody?.friction = self.defaultFriction
                        child.physicsBody?.restitution = self.defaultRestitution
                        child.physicsBody?.isAffectedByGravity = false // Kinematic bodies are not affected by gravity by default
                        // For kinematic bodies, ensure they can cause collisions
                        child.physicsBody?.categoryBitMask = 1 // Example category
                        child.physicsBody?.contactTestBitMask = 2 // Example: Collide with objects of category 2
                        child.physicsBody?.collisionBitMask = 2 // Example: Collide with objects of category 2
                    }
                    scannedNode.addChildNode(child)
                }
                
                // Add to scene on main thread
                DispatchQueue.main.async {
                    // Remove any existing scanned node
                    self.scannedNode?.removeFromParentNode()
                    
                    print("PhysicsView: adding scanned model to scene")
                    
                    // Position the scanned node at the center of the scene
                    scannedNode.position = SCNVector3(0, 0, 0)
                    
                    // Add the new scanned node to the scene
                    self.arView.scene.rootNode.addChildNode(scannedNode)
                    self.scannedNode = scannedNode
                    
                    // Start AR session with proper configuration
                    let configuration = ARWorldTrackingConfiguration()
                    configuration.planeDetection = [.horizontal, .vertical]
                    self.session.run(configuration)
                }
            } catch {
                print("Error loading model: \(error.localizedDescription)")
            }
        }
    }
    
    /// Add a physics object to the scene
    func addPhysicsObject(objectData: [String: Any]) -> Bool {
        guard let id = objectData["id"] as? String,
              let type = objectData["type"] as? String,
              let position = objectData["position"] as? [Double],
              let scale = objectData["scale"] as? [Double],
              let colorData = objectData["color"] as? [Int],
              let mass = objectData["mass"] as? Double else {
            print("Invalid object data")
            return false
        }
        
        print("PhysicsView: adding object of type \(type) at position \(position)")
        
        // Create geometry based on type
        var geometry: SCNGeometry
        switch type {
        case "sphere":
            geometry = SCNSphere(radius: CGFloat(scale[0]))
        case "cube":
            geometry = SCNBox(
                width: CGFloat(scale[0] * 2),
                height: CGFloat(scale[1] * 2),
                length: CGFloat(scale[2] * 2),
                chamferRadius: 0
            )
        case "cylinder":
            geometry = SCNCylinder(
                radius: CGFloat(scale[0]),
                height: CGFloat(scale[1] * 2)
            )
        default:
            print("Unknown object type: \(type)")
            return false
        }
        
        // Create material
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(
            red: CGFloat(colorData[0]) / 255.0,
            green: CGFloat(colorData[1]) / 255.0,
            blue: CGFloat(colorData[2]) / 255.0,
            alpha: CGFloat(colorData[3]) / 255.0
        )
        geometry.materials = [material]
        
        // Create node
        let node = SCNNode(geometry: geometry)
        node.position = SCNVector3(
            x: Float(position[0]),
            y: Float(position[1]),
            z: Float(position[2])
        )
        
        // Add physics body
        let physicsShape = SCNPhysicsShape(geometry: geometry, options: nil)
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        node.physicsBody?.mass = CGFloat(mass)
        node.physicsBody?.friction = defaultFriction
        node.physicsBody?.restitution = defaultRestitution
        // Configure bitmasks for interaction with the kinematic environment
        node.physicsBody?.categoryBitMask = 2 // This object is of category 2
        node.physicsBody?.collisionBitMask = 1 // Collide with objects of category 1 (the environment)
        node.physicsBody?.contactTestBitMask = 1 // Notify contacts with category 1 (the environment)
        
        // Store the object and add it to the scene
        physicsObjects[id] = node
        arView.scene.rootNode.addChildNode(node)
        
        return true
    }
    
    /// Remove a physics object from the scene
    func removePhysicsObject(objectId: String) -> Bool {
        guard let node = physicsObjects[objectId] else {
            return false
        }
        
        node.removeFromParentNode()
        physicsObjects.removeValue(forKey: objectId)
        return true
    }
    
    /// Clear all physics objects from the scene
    func clearPhysicsObjects() {
        print("PhysicsView: clearing all objects")
        
        for (_, node) in physicsObjects {
            node.removeFromParentNode()
        }
        physicsObjects.removeAll()
    }
    
    /// Adjust the position of the scanned model in the scene
    func adjustModelPosition(screenDeltaX: Double, screenDeltaY: Double) -> Bool {
        guard let node = scannedNode, let camera = arView.pointOfView else {
            print("PhysicsView: No scanned model or camera to adjust")
            return false
        }

        // Sensitivity factor for movement - adjust as needed
        let sensitivity: Float = 0.001

        let cameraTransform = camera.transform

        // Camera's "forward" vector in the horizontal plane (points away from camera)
        let cameraForward = SCNVector3(-cameraTransform.m31, 0, -cameraTransform.m33)
        
        // Camera's "right" vector in the horizontal plane
        let cameraRight = SCNVector3(cameraTransform.m11, 0, cameraTransform.m13)

        // Convert screen drags to world movement relative to camera
        let moveIncrementRight = cameraRight * Float(screenDeltaX)
        let moveIncrementForward = cameraForward * Float(-screenDeltaY) // Invert screenDeltaY for intuitive forward movement

        let totalMoveInWorld = SCNVector3(
            moveIncrementRight.x + moveIncrementForward.x,
            0, // No vertical movement from this gesture on the horizontal plane
            moveIncrementRight.z + moveIncrementForward.z
        ) * sensitivity // Apply sensitivity to the combined horizontal movement
        
        // Apply incremental position change
        node.position = SCNVector3(
            node.position.x + totalMoveInWorld.x,
            node.position.y, // Keep current Y position (height)
            node.position.z + totalMoveInWorld.z
        )

        print("PhysicsView: Model position adjusted by worldDelta: (\(totalMoveInWorld.x), 0, \(totalMoveInWorld.z)) to newPos: \(node.position)")
        return true
    }
    
    /// Rotate the model around its Y axis
    func rotateModelY(angle: Double) -> Bool {
        guard let node = scannedNode else {
            print("PhysicsView: No scanned model to rotate")
            return false
        }
        
        // Convert angle to radians
        let angleRadians = Float(angle * .pi / 180.0)
        
        // Create rotation matrix around Y axis
        let rotationMatrix = SCNMatrix4MakeRotation(angleRadians, 0, 1, 0)
        
        // Apply rotation
        node.transform = SCNMatrix4Mult(node.transform, rotationMatrix)
        
        print("PhysicsView: Model rotated by \(angle) degrees")
        return true
    }
    
    /// Resets the model position to the world origin (0,0,0) and identity rotation.
    func resetModelPositionToOrigin() -> Bool {
        guard let node = scannedNode else {
            print("PhysicsView: No scanned model to reset")
            return false
        }
        
        node.position = SCNVector3(0, 0, 0)
        node.transform = SCNMatrix4Identity // Reset rotation as well
        // Alternatively, for only rotation reset on Y axis:
        // node.rotation = SCNVector4(0, 1, 0, 0)
        
        print("PhysicsView: Model position and rotation reset to origin and identity.")
        return true
    }
    
    /// Set the visibility of the scanned mesh while preserving physics
    func setMeshVisibility(visible: Bool) -> Bool {
        // IMPORTANT: Inverting the parameter logic to match UI expectations
        // visible=true now means "show mesh" (make it visible)
        // visible=false now means "hide mesh" (make it invisible but keep collisions)
        let shouldHideMesh = !visible
        
        print("PhysicsView: setting mesh visibility to: \(visible) (hideMesh=\(shouldHideMesh))")

        guard let scannedNode = scannedNode else {
            print("PhysicsView: cannot set visibility, scanned node is nil")
            return false
        }
        
        // Toggle debug visualizations based on visibility
        if visible {
            // Only show debug visualizations if it was previously enabled
            if showDebugVisualization {
                arView.debugOptions = [.showPhysicsShapes]
            }
        } else {
            // Always disable debug visualizations when hiding mesh to ensure it's not visible
            arView.debugOptions = []
        }

        // Apply visibility changes to all child nodes with geometry
        scannedNode.enumerateChildNodes { (node, _) in
            if node.geometry != nil {
                applyVisibility(to: node, visible: visible)
            }
        }
        
        // Also apply visibility changes to the parent scannedNode itself, 
        // in case it has its own geometry or to ensure consistent state.
        if scannedNode.geometry != nil {
            applyVisibility(to: scannedNode, visible: visible)
        } else {
            // If scannedNode has no geometry, still set its opacity and renderingOrder
            // to control overall group visibility if needed, though child settings should dominate.
            scannedNode.opacity = visible ? 0.8 : 0.0
            scannedNode.renderingOrder = visible ? 0 : -10
            
            // When hiding, ensure we're fully transparent
            if !visible {
                scannedNode.categoryBitMask = 0
            }
        }

        print("PhysicsView: mesh visibility set successfully to \(visible)")
        return true
    }

    // Helper function to apply visibility properties to a node
    private func applyVisibility(to node: SCNNode, visible: Bool) {
        // Store the current physics body to restore later
        let physicsBody = node.physicsBody
        
        if visible {
            // Make the node visible with semi-transparent material
            node.isHidden = false  // Make sure node is visible
            node.opacity = 0.8
            node.castsShadow = true
            node.categoryBitMask = 1 // Default rendering category
            
            // Apply semi-transparent material
            if node.geometry?.materials.isEmpty ?? true {
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.lightGray.withAlphaComponent(0.8)
                material.isDoubleSided = true
                material.transparency = 0.2
                material.lightingModel = .blinn
                node.geometry?.materials = [material]
            } else {
                for material in node.geometry?.materials ?? [] {
                    material.transparency = 0.2
                    material.diffuse.contents = UIColor.lightGray.withAlphaComponent(0.8)
                    material.lightingModel = .blinn
                }
            }
            
            node.renderingOrder = 0 // Default rendering order
        } else {
            // SOLUTION #1: Use a combination of advanced techniques to make the mesh invisible
            
            // Set geometry materials to fully transparent
            if let geometry = node.geometry {
                // Create completely transparent material that maintains physics
                let invisibleMaterial = SCNMaterial()
                invisibleMaterial.diffuse.contents = UIColor.clear
                invisibleMaterial.specular.contents = UIColor.clear
                invisibleMaterial.ambient.contents = UIColor.clear
                invisibleMaterial.emission.contents = UIColor.clear
                
                // Set all transparency values to ensure it's fully invisible
                invisibleMaterial.transparency = 1.0
                invisibleMaterial.transparencyMode = .dualLayer
                invisibleMaterial.writesToDepthBuffer = true  // Important for physics
                invisibleMaterial.readsFromDepthBuffer = true // Important for physics
                invisibleMaterial.isDoubleSided = true
                
                // Apply to geometry
                geometry.materials = [invisibleMaterial]
            }
            
            // Configure node properties for invisibility while maintaining physics
            node.opacity = 0.0
            node.castsShadow = false
            node.renderingOrder = -10
            
            // Set the node's opacity modifier to hide it even more effectively
            node.categoryBitMask = 0 // Remove from visible rendering categories, but keep physics
        }
        
        // IMPORTANT: Restore physics body to ensure collisions work
        node.physicsBody = physicsBody
        
        // Force update rendering
        node.geometry?.firstMaterial?.readsFromDepthBuffer = visible ? true : true
    }
    
    /// Get the current camera position in the scene
    func getCameraPosition() -> [Double] {
        // Get the current camera node
        guard let cameraNode = arView.pointOfView else {
            // Default position if camera not available
            return [0.0, 1.0, 0.0]
        }
        
        // Get the camera's world position
        let position = cameraNode.worldPosition
        
        // Return position as array of doubles
        return [
            Double(position.x),
            Double(position.y),
            Double(position.z)
        ]
    }
    
    /// Apply a force to an object
    func applyForce(objectId: String, force: [Double], position: [Double]) {
        guard let node = physicsObjects[objectId],
              let physicsBody = node.physicsBody else {
            return
        }
        
        let forceVector = SCNVector3(
            x: Float(force[0]),
            y: Float(force[1]),
            z: Float(force[2])
        )
        
        let positionVector = SCNVector3(
            x: Float(position[0]),
            y: Float(position[1]),
            z: Float(position[2])
        )
        
        physicsBody.applyForce(forceVector, at: positionVector, asImpulse: true)
    }
    
    /// Convert screen coordinates to world position
    func screenToWorldPosition(x: Double, y: Double) -> [Double]? {
        let screenPoint = CGPoint(x: x, y: y)
        
        // Perform hit test against existing geometry
        let hitTestResults = arView.hitTest(screenPoint, options: [
            SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue
        ])
        
        // If we hit something, return that position
        if let result = hitTestResults.first {
            let hitPosition = result.worldCoordinates
            return [Double(hitPosition.x), Double(hitPosition.y), Double(hitPosition.z)]
        }
        
        // If no hit, return a position 1 meter in front of the camera
        let pointInFrontOfCamera = SCNVector3(x: 0, y: 0, z: -1)
        guard let cameraNode = arView.pointOfView else {
            return [0, 0, -1]
        }
        
        let worldPosition = cameraNode.convertPosition(pointInFrontOfCamera, to: nil)
        
        return [Double(worldPosition.x), Double(worldPosition.y), Double(worldPosition.z)]
    }
    
    /// Get the current FPS
    func getFps() -> Double {
        return currentFps
    }
    
    /// Set physics parameters (gravity, friction, restitution)
    func setPhysicsParameters(parameters: [String: Any]) {
        if let gravity = parameters["gravity"] as? Double {
            physicsScene.gravity = SCNVector3(0, Float(gravity), 0)
            self.gravity = Float(gravity)
        }
        
        if let friction = parameters["friction"] as? Double {
            defaultFriction = CGFloat(friction)
            // Update existing objects
            for (_, node) in physicsObjects {
                node.physicsBody?.friction = defaultFriction
            }
        }
        
        if let restitution = parameters["restitution"] as? Double {
            defaultRestitution = CGFloat(restitution)
            // Update existing objects
            for (_, node) in physicsObjects {
                node.physicsBody?.restitution = defaultRestitution
            }
        }
    }
    
    // MARK: - Private methods
    
    private func configurePhysicsWorld() {
        // Set up physics world properties
        physicsScene.gravity = SCNVector3(0, gravity, 0)
        
        // Set up collision detection
        physicsScene.contactDelegate = self
    }
    
    private func setupFrameTiming() {
        // Add a display link to calculate FPS
        let displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        displayLink.add(to: .main, forMode: .common)
    }
    
    @objc private func handleDisplayLink(_ displayLink: CADisplayLink) {
        let currentTime = CACurrentMediaTime()
        
        frameCount += 1
        
        // Update FPS every second
        if currentTime - lastFrameTime >= 1.0 {
            currentFps = Double(frameCount) / (currentTime - lastFrameTime)
            frameCount = 0
            lastFrameTime = currentTime
        }
    }
}

// MARK: - SCNPhysicsContactDelegate
extension PhysicsView: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        // Handle collision events if needed
    }
} 