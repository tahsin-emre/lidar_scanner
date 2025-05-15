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

// Extension to create SCNGeometry from ARMeshAnchor
@available(iOS 13.4, *)
extension SCNGeometry {
    static func from(meshAnchor: ARMeshAnchor) -> SCNGeometry {
        let geometry = SCNGeometry(arGeometry: meshAnchor.geometry)
        return geometry
    }
}

/// A view that handles physics simulation with LiDAR-scanned meshes
class PhysicsView: NSObject, FlutterPlatformView, ARSCNViewDelegate {
    // MARK: - Properties
    private var arView: ARSCNView!
    private let session = ARSession()
    
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
        
        // Configure debug visualization if needed
        if let args = args as? [String: Any],
           let initialConfig = args["initialConfiguration"] as? [String: Any],
           let enableDebug = initialConfig["enableDebugVisualization"] as? Bool, 
           enableDebug {
            showDebugVisualization = enableDebug
            arView.debugOptions = [.showPhysicsShapes]
        } else {
            arView.debugOptions = []
        }
        
        configurePhysicsWorld()
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
        
        guard let url = URL(string: scanPath) else {
            print("Error: Invalid scan path URL")
            return
        }
        
        // Load the model in background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Load asset and convert to SCNScene
                let asset = MDLAsset(url: url)
                let scene = SCNScene(mdlAsset: asset)
                let scannedNode = SCNNode()
                
                // Process all child nodes
                for child in scene.rootNode.childNodes {
                    if let geometry = child.geometry {
                        // Configure material for occlusion
                        let material = SCNMaterial()
                        material.diffuse.contents = UIColor.lightGray.withAlphaComponent(0.8)
                        material.isDoubleSided = true
                        material.writesToDepthBuffer = true
                        material.readsFromDepthBuffer = true
                        geometry.materials = [material]
                        
                        // Create physics shape for collision
                        let physicsShape = SCNPhysicsShape(
                            geometry: geometry,
                            options: [
                                SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron,
                                SCNPhysicsShape.Option.keepAsCompound: true,
                                SCNPhysicsShape.Option.collisionMargin: 0.01
                            ]
                        )
                        
                        // Configure physics body
                        child.physicsBody = SCNPhysicsBody(type: .kinematic, shape: physicsShape)
                        child.physicsBody?.friction = self.defaultFriction
                        child.physicsBody?.restitution = self.defaultRestitution
                        child.physicsBody?.isAffectedByGravity = false
                        child.physicsBody?.categoryBitMask = 1
                        child.physicsBody?.contactTestBitMask = 2
                        child.physicsBody?.collisionBitMask = 2
                        
                        // Set rendering order for occlusion
                        child.renderingOrder = -10
                    }
                    scannedNode.addChildNode(child)
                }
                
                // Update scene on main thread
                DispatchQueue.main.async {
                    // Remove existing scanned node if any
                    self.scannedNode?.removeFromParentNode()
                    
                    // Position and add the new scanned node
                    scannedNode.position = SCNVector3(0, 0, 0)
                    scannedNode.renderingOrder = -10
                    self.arView.scene.rootNode.addChildNode(scannedNode)
                    self.scannedNode = scannedNode
                    
                    // Start AR session with mesh reconstruction if supported
                    let configuration = ARWorldTrackingConfiguration()
                    configuration.planeDetection = [.horizontal, .vertical]
                    
                    // Enable mesh reconstruction for LiDAR-equipped devices
                    if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                        configuration.sceneReconstruction = .mesh
                    }
                    
                    // Set the session delegate to handle ARMeshAnchors
                    self.arView.session.delegate = self
                    
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
        
        // Create material with proper depth settings
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(
            red: CGFloat(colorData[0]) / 255.0,
            green: CGFloat(colorData[1]) / 255.0,
            blue: CGFloat(colorData[2]) / 255.0,
            alpha: CGFloat(colorData[3]) / 255.0
        )
        material.readsFromDepthBuffer = true
        material.writesToDepthBuffer = true
        geometry.materials = [material]
        
        // Create node
        let node = SCNNode(geometry: geometry)
        node.position = SCNVector3(
            x: Float(position[0]),
            y: Float(position[1]),
            z: Float(position[2])
        )
        
        // Configure physics
        let physicsShape = SCNPhysicsShape(geometry: geometry, options: nil)
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        node.physicsBody?.mass = CGFloat(mass)
        node.physicsBody?.friction = defaultFriction
        node.physicsBody?.restitution = defaultRestitution
        node.physicsBody?.categoryBitMask = 2
        node.physicsBody?.collisionBitMask = 1
        node.physicsBody?.contactTestBitMask = 1
        
        // Set rendering order for occlusion
        node.renderingOrder = 1000
        
        // Add to scene
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
        for (_, node) in physicsObjects {
            node.removeFromParentNode()
        }
        physicsObjects.removeAll()
    }
    
    /// Adjust the position of the scanned model in the scene
    func adjustModelPosition(screenDeltaX: Double, screenDeltaY: Double) -> Bool {
        guard let node = scannedNode, let camera = arView.pointOfView else {
            return false
        }

        // Sensitivity factor for movement
        let sensitivity: Float = 0.001
        let cameraTransform = camera.transform

        // Get camera vectors
        let cameraForward = SCNVector3(-cameraTransform.m31, 0, -cameraTransform.m33)
        let cameraRight = SCNVector3(cameraTransform.m11, 0, cameraTransform.m13)

        // Calculate movement
        let moveIncrementRight = cameraRight * Float(screenDeltaX)
        let moveIncrementForward = cameraForward * Float(-screenDeltaY)
        let totalMoveInWorld = SCNVector3(
            moveIncrementRight.x + moveIncrementForward.x,
            0,
            moveIncrementRight.z + moveIncrementForward.z
        ) * sensitivity
        
        // Apply movement
        node.position = SCNVector3(
            node.position.x + totalMoveInWorld.x,
            node.position.y,
            node.position.z + totalMoveInWorld.z
        )

        return true
    }
    
    /// Rotate the model around its Y axis
    func rotateModelY(angle: Double) -> Bool {
        guard let node = scannedNode else {
            return false
        }
        
        let angleRadians = Float(angle * .pi / 180.0)
        let rotationMatrix = SCNMatrix4MakeRotation(angleRadians, 0, 1, 0)
        node.transform = SCNMatrix4Mult(node.transform, rotationMatrix)
        
        return true
    }
    
    /// Reset model position and rotation to origin
    func resetModelPositionToOrigin() -> Bool {
        guard let node = scannedNode else {
            return false
        }
        
        node.position = SCNVector3(0, 0, 0)
        node.transform = SCNMatrix4Identity
        
        return true
    }
    
    /// Set the visibility of the scanned mesh while preserving physics
    func setMeshVisibility(visible: Bool) -> Bool {
        guard let scannedNode = scannedNode else {
            return false
        }
        
        // Update debug visualization
        if visible && showDebugVisualization {
            arView.debugOptions = [.showPhysicsShapes]
        } else {
            arView.debugOptions = []
        }

        // Apply to all child nodes with geometry
        scannedNode.enumerateChildNodes { (node, _) in
            if node.geometry != nil {
                applyVisibility(to: node, visible: visible)
            }
        }
        
        // Apply to parent node if needed
        if scannedNode.geometry != nil {
            applyVisibility(to: scannedNode, visible: visible)
        } else {
            // Set parent node properties
            if visible {
                scannedNode.opacity = 0.8
                scannedNode.renderingOrder = 0
                scannedNode.categoryBitMask = 1
            } else {
                scannedNode.opacity = 1.0
                scannedNode.renderingOrder = -1
                scannedNode.categoryBitMask = 2
            }
        }

        return true
    }

    // Helper function to apply visibility properties to a node
    private func applyVisibility(to node: SCNNode, visible: Bool) {
        // Store physics body to restore later
        let physicsBody = node.physicsBody
        
        if visible {
            // Make the node visible
            node.isHidden = false
            node.opacity = 0.8
            node.castsShadow = true
            node.categoryBitMask = 1
            node.renderingOrder = -10
            
            // Apply semi-transparent material
            if node.geometry?.materials.isEmpty ?? true {
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.lightGray.withAlphaComponent(0.8)
                material.isDoubleSided = true
                material.transparency = 0.7
                material.lightingModel = .blinn
                material.writesToDepthBuffer = true
                material.readsFromDepthBuffer = true
                node.geometry?.materials = [material]
            } else {
                for material in node.geometry?.materials ?? [] {
                    material.transparency = 0.7
                    material.diffuse.contents = UIColor.lightGray.withAlphaComponent(0.8)
                    material.lightingModel = .blinn
                    material.writesToDepthBuffer = true
                    material.readsFromDepthBuffer = true
                }
            }
        } else {
            // Create occlusion material (invisible but blocks objects behind it)
            if let geometry = node.geometry {
                let occlusionMaterial = SCNMaterial()
                occlusionMaterial.diffuse.contents = UIColor.black
                occlusionMaterial.colorBufferWriteMask = []
                occlusionMaterial.writesToDepthBuffer = true
                occlusionMaterial.readsFromDepthBuffer = false
                occlusionMaterial.isDoubleSided = true
                
                // Apply to all surfaces
                geometry.materials = Array(repeating: occlusionMaterial, count: max(1, geometry.materials.count))
            }
            
            // Configure node for occlusion
            node.isHidden = false
            node.opacity = 1.0
            node.renderingOrder = -100
            node.categoryBitMask = 4
            node.castsShadow = false
        }
        
        // Restore physics body
        node.physicsBody = physicsBody
    }
    
    /// Get the current camera position
    func getCameraPosition() -> [Double] {
        guard let cameraNode = arView.pointOfView else {
            return [0.0, 1.0, 0.0]
        }
        
        let position = cameraNode.worldPosition
        return [Double(position.x), Double(position.y), Double(position.z)]
    }
    
    /// Apply a force to an object
    func applyForce(objectId: String, force: [Double], position: [Double]) {
        guard let node = physicsObjects[objectId], let physicsBody = node.physicsBody else {
            return
        }
        
        let forceVector = SCNVector3(x: Float(force[0]), y: Float(force[1]), z: Float(force[2]))
        let positionVector = SCNVector3(x: Float(position[0]), y: Float(position[1]), z: Float(position[2]))
        
        physicsBody.applyForce(forceVector, at: positionVector, asImpulse: true)
    }
    
    /// Convert screen coordinates to world position
    func screenToWorldPosition(x: Double, y: Double) -> [Double]? {
        let screenPoint = CGPoint(x: x, y: y)
        
        // Try hit test first
        let hitTestResults = arView.hitTest(screenPoint, options: [
            SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue
        ])
        
        if let result = hitTestResults.first {
            let hitPosition = result.worldCoordinates
            return [Double(hitPosition.x), Double(hitPosition.y), Double(hitPosition.z)]
        }
        
        // Fall back to position in front of camera
        guard let cameraNode = arView.pointOfView else {
            return [0, 0, -1]
        }
        
        let pointInFrontOfCamera = SCNVector3(x: 0, y: 0, z: -1)
        let worldPosition = cameraNode.convertPosition(pointInFrontOfCamera, to: nil)
        
        return [Double(worldPosition.x), Double(worldPosition.y), Double(worldPosition.z)]
    }
    
    /// Get the current FPS
    func getFps() -> Double {
        return currentFps
    }
    
    /// Set physics parameters
    func setPhysicsParameters(parameters: [String: Any]) {
        if let gravity = parameters["gravity"] as? Double {
            physicsScene.gravity = SCNVector3(0, Float(gravity), 0)
            self.gravity = Float(gravity)
        }
        
        if let friction = parameters["friction"] as? Double {
            defaultFriction = CGFloat(friction)
            for (_, node) in physicsObjects {
                node.physicsBody?.friction = defaultFriction
            }
        }
        
        if let restitution = parameters["restitution"] as? Double {
            defaultRestitution = CGFloat(restitution)
            for (_, node) in physicsObjects {
                node.physicsBody?.restitution = defaultRestitution
            }
        }
    }
    
    // MARK: - Private methods
    
    private func configurePhysicsWorld() {
        physicsScene.gravity = SCNVector3(0, gravity, 0)
        physicsScene.contactDelegate = self
    }
    
    private func setupFrameTiming() {
        let displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        displayLink.add(to: .main, forMode: .common)
    }
    
    @objc private func handleDisplayLink(_ displayLink: CADisplayLink) {
        let currentTime = CACurrentMediaTime()
        frameCount += 1
        
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
        // Collision handling can be added here if needed
    }
}

// MARK: - ARSessionDelegate
extension PhysicsView: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let meshAnchor = anchor as? ARMeshAnchor {
                addMeshAnchor(meshAnchor)
            }
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let meshAnchor = anchor as? ARMeshAnchor {
                addMeshAnchor(meshAnchor)
            }
        }
    }
    
    private func addMeshAnchor(_ meshAnchor: ARMeshAnchor) {
        let geometry = SCNGeometry.from(meshAnchor: meshAnchor)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.clear
        material.colorBufferWriteMask = []
        material.writesToDepthBuffer = true
        material.isDoubleSided = true
        geometry.materials = [material]

        let node = SCNNode(geometry: geometry)
        node.renderingOrder = -100
        node.opacity = 1.0
        node.categoryBitMask = 4
        node.castsShadow = false
        node.transform = SCNMatrix4(meshAnchor.transform)

        arView.scene.rootNode.addChildNode(node)
    }
} 