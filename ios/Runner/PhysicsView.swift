//
//  PhysicsView.swift
//  Runner
//

import Foundation
import ARKit
import SceneKit
import SceneKit.ModelIO
import Metal

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
        // Use the init(arGeometry:) constructor that's defined in ARExtensions.swift
        return SCNGeometry(arGeometry: meshAnchor.geometry)
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
    
    // Selected object type for physics objects
    private var selectedObjectType: String = "sphere"
    
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
                        print("Device supports LiDAR mesh reconstruction")
                        configuration.sceneReconstruction = .mesh
                        configuration.frameSemantics.insert(.personSegmentationWithDepth)
                    } else {
                        print("Device does NOT support LiDAR mesh reconstruction")
                    }
                    
                    // IMPORTANT: Set the session delegate to handle ARMeshAnchors
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
              let position = objectData["position"] as? [Double],
              let scale = objectData["scale"] as? [Double],
              let colorData = objectData["color"] as? [Int],
              let mass = objectData["mass"] as? Double else {
            print("Invalid object data")
            return false
        }
        
        // Use selected object type if not specified in the objectData
        let type = objectData["type"] as? String ?? selectedObjectType
        
        // Create geometry based on type
        var geometry: SCNGeometry
        var node: SCNNode
        
        switch type {
        case "sphere":
            geometry = SCNSphere(radius: CGFloat(scale[0]))
            node = SCNNode(geometry: geometry)
            
            // Küre için özel materyal
            let sphereMaterial = SCNMaterial()
            sphereMaterial.diffuse.contents = UIColor(
                red: CGFloat(colorData[0]) / 255.0,
                green: CGFloat(colorData[1]) / 255.0,
                blue: CGFloat(colorData[2]) / 255.0,
                alpha: CGFloat(colorData[3]) / 255.0
            )
            sphereMaterial.metalness.contents = 0.6
            sphereMaterial.roughness.contents = 0.3
            sphereMaterial.lightingModel = .physicallyBased
            node.geometry?.materials = [sphereMaterial]
            
            // Fizik özelliklerini ayarla
            let spherePhysicsShape = SCNPhysicsShape(
                geometry: geometry,
                options: [
                    SCNPhysicsShape.Option.keepAsCompound: false,
                    SCNPhysicsShape.Option.collisionMargin: 0.01
                ]
            )
            
            node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: spherePhysicsShape)
            node.physicsBody?.mass = CGFloat(mass)
            node.physicsBody?.restitution = 0.7    // Daha çok zıplasın
            node.physicsBody?.rollingFriction = 0.1 // Yuvarlanma direnci çok düşük
            node.physicsBody?.friction = 0.2       // Az sürtünme
            
            // Çarpışma maskeleri
            node.physicsBody?.categoryBitMask = 2
            node.physicsBody?.collisionBitMask = 1 + 2 + 4
            node.physicsBody?.contactTestBitMask = 1 + 2
            
            // Rastgele dönüş hareketi
            node.physicsBody?.angularVelocity = SCNVector4(
                Float.random(in: -2...2),
                Float.random(in: -2...2),
                Float.random(in: -2...2),
                Float.random(in: 0...3)
            )
            
        case "cube":
            geometry = SCNBox(
                width: CGFloat(scale[0] * 2),
                height: CGFloat(scale[1] * 2),
                length: CGFloat(scale[2] * 2),
                chamferRadius: 0.001 // Hafif yuvarlatılmış kenarlar
            )
            node = SCNNode(geometry: geometry)
            
            // Küp için özel materyal
            let cubeMaterial = SCNMaterial()
            cubeMaterial.diffuse.contents = UIColor(
                red: CGFloat(colorData[0]) / 255.0,
                green: CGFloat(colorData[1]) / 255.0,
                blue: CGFloat(colorData[2]) / 255.0,
                alpha: CGFloat(colorData[3]) / 255.0
            )
            cubeMaterial.metalness.contents = 0.3
            cubeMaterial.roughness.contents = 0.6
            cubeMaterial.lightingModel = .physicallyBased
            
            // Tüm yüzeylere aynı materyal
            node.geometry?.materials = Array(repeating: cubeMaterial, count: 6)
            
            // Fizik özelliklerini ayarla
            let cubePhysicsShape = SCNPhysicsShape(
                geometry: geometry,
                options: [
                    SCNPhysicsShape.Option.keepAsCompound: false,
                    SCNPhysicsShape.Option.collisionMargin: 0.01
                ]
            )
            
            node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: cubePhysicsShape)
            node.physicsBody?.mass = CGFloat(mass)
            node.physicsBody?.restitution = 0.4    // Orta seviye zıplama
            node.physicsBody?.rollingFriction = 0.5 // Yuvarlanma direnci yüksek
            node.physicsBody?.friction = 0.6       // Yüksek sürtünme
            
            // Çarpışma maskeleri
            node.physicsBody?.categoryBitMask = 2
            node.physicsBody?.collisionBitMask = 1 + 2 + 4
            node.physicsBody?.contactTestBitMask = 1 + 2
            
            // Rastgele dönüş hareketi
            node.physicsBody?.angularVelocity = SCNVector4(
                Float.random(in: -1.5...1.5),
                Float.random(in: -1.5...1.5),
                Float.random(in: -1.5...1.5),
                Float.random(in: 0...2)
            )
            
        case "cylinder":
            geometry = SCNCylinder(
                radius: CGFloat(scale[0]),
                height: CGFloat(scale[1] * 2)
            )
            node = SCNNode(geometry: geometry)
            
            // Silindir için özel materyal
            let cylinderMaterial = SCNMaterial()
            cylinderMaterial.diffuse.contents = UIColor(
                red: CGFloat(colorData[0]) / 255.0,
                green: CGFloat(colorData[1]) / 255.0,
                blue: CGFloat(colorData[2]) / 255.0,
                alpha: CGFloat(colorData[3]) / 255.0
            )
            cylinderMaterial.metalness.contents = 0.4
            cylinderMaterial.roughness.contents = 0.5
            cylinderMaterial.lightingModel = .physicallyBased
            
            // Üst ve alt kapaklar için materyal
            let capMaterial = SCNMaterial()
            capMaterial.diffuse.contents = cylinderMaterial.diffuse.contents
            capMaterial.metalness.contents = cylinderMaterial.metalness.contents
            capMaterial.roughness.contents = 0.7 // Kapaklar daha pürüzlü
            capMaterial.lightingModel = .physicallyBased
            
            // Silindirin yan yüzeyi ve kapakları için materyal ayarla
            node.geometry?.materials = [cylinderMaterial, capMaterial, capMaterial]
            
            // Silindir yatay konumda olsun
            node.eulerAngles = SCNVector3(Float.pi/2, 0, 0)
            
            // Fizik özelliklerini ayarla
            let cylinderPhysicsShape = SCNPhysicsShape(
                geometry: geometry,
                options: [
                    SCNPhysicsShape.Option.keepAsCompound: false,
                    SCNPhysicsShape.Option.collisionMargin: 0.01
                ]
            )
            
            node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: cylinderPhysicsShape)
            node.physicsBody?.mass = CGFloat(mass)
            node.physicsBody?.restitution = 0.5    // Orta seviye zıplama
            node.physicsBody?.rollingFriction = 0.3 // Orta seviye yuvarlanma direnci
            node.physicsBody?.friction = 0.4       // Orta seviye sürtünme
            
            // Çarpışma maskeleri
            node.physicsBody?.categoryBitMask = 2
            node.physicsBody?.collisionBitMask = 1 + 2 + 4
            node.physicsBody?.contactTestBitMask = 1 + 2
            
            // Rastgele dönüş hareketi - silindirler için daha fazla yuvarlanma
            node.physicsBody?.angularVelocity = SCNVector4(
                Float.random(in: -0.5...0.5),
                Float.random(in: -2...2),
                Float.random(in: -0.5...0.5),
                Float.random(in: 0...3)
            )
            
        case "coin":
            // Madeni para - ince yassı bir silindir
            geometry = SCNCylinder(
                radius: CGFloat(scale[0]),
                height: CGFloat(scale[1]) // Çok ince
            )
            node = SCNNode(geometry: geometry)
            
            // Paralara özgü metalik görünüm
            let coinMaterial = SCNMaterial()
            
            // Renk seçeneğine göre altın veya gümüş renk ver
            if colorData[0] > 200 && colorData[1] > 200 && colorData[2] > 200 {
                // Gümüş/platin para
                coinMaterial.diffuse.contents = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
                coinMaterial.metalness.contents = 0.9
                coinMaterial.roughness.contents = 0.1
            } else {
                // Altın para
                coinMaterial.diffuse.contents = UIColor(red: 0.85, green: 0.65, blue: 0.10, alpha: 1.0)
                coinMaterial.metalness.contents = 0.8
                coinMaterial.roughness.contents = 0.2
            }
            
            // İkinci materyal - kenar materyal
            let edgeMaterial = SCNMaterial()
            edgeMaterial.diffuse.contents = coinMaterial.diffuse.contents
            edgeMaterial.metalness.contents = coinMaterial.metalness.contents
            edgeMaterial.roughness.contents = 0.4 // Kenarlar biraz daha pürüzlü
            
            // Paranın üst ve alt yüzeyleri ile kenar materyallerini ayarla
            coinMaterial.lightingModel = .physicallyBased
            edgeMaterial.lightingModel = .physicallyBased
            node.geometry?.materials = [coinMaterial, edgeMaterial, coinMaterial]
            
            // Para düz düşsün diye rotasyonu ayarla
            node.eulerAngles = SCNVector3(Float.pi/2, 0, 0)
            
            // Fizik özelliklerini para gibi ayarla 
            let physicsShape = SCNPhysicsShape(
                geometry: geometry,
                options: [
                    SCNPhysicsShape.Option.keepAsCompound: false,
                    SCNPhysicsShape.Option.collisionMargin: 0.005
                ]
            )
            
            // Düzgün çarpışma için daha iyi physics body konfigürasyonu
            node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
            node.physicsBody?.mass = CGFloat(mass) // Kütleyi parametre olarak al
            node.physicsBody?.restitution = 0.3    // Az zıplasın
            node.physicsBody?.rollingFriction = 0.2 // Yuvarlanma direnci düşük
            node.physicsBody?.friction = 0.3       // Sürtünmeyi arttır
            
            // Çarpışma maskeleri - önemli
            node.physicsBody?.categoryBitMask = 2  // 2 = Hareketli objeler
            node.physicsBody?.collisionBitMask = 1 + 2 + 4  // Statik mesh (1), diğer objeler (2) ve oklüzyon mesh (4) ile çarpışsın
            node.physicsBody?.contactTestBitMask = 1 + 2  // Statik mesh (1) ve diğer objeler (2) ile temas etsin
            
            // Yuvarlanma hareketi ekle - gerçekçi düşüş için
            node.physicsBody?.angularVelocity = SCNVector4(
                Float.random(in: -1...1), 
                Float.random(in: -1...1), 
                Float.random(in: -1...1), 
                Float.random(in: 0...2)
            )
            
        default:
            geometry = SCNSphere(radius: CGFloat(scale[0]))
            node = SCNNode(geometry: geometry)
        }
        
        // Create material with proper depth settings (for standard geometry types)
        if type != "usdz" || node.geometry != nil {
            let material = SCNMaterial()
            material.diffuse.contents = UIColor(
                red: CGFloat(colorData[0]) / 255.0,
                green: CGFloat(colorData[1]) / 255.0,
                blue: CGFloat(colorData[2]) / 255.0,
                alpha: CGFloat(colorData[3]) / 255.0
            )
            material.readsFromDepthBuffer = true
            material.writesToDepthBuffer = true
            node.geometry?.materials = [material]
            
            // Create physics body for standard geometry types
            if node.physicsBody == nil {
                let physicsShape = SCNPhysicsShape(geometry: node.geometry!, options: nil)
                node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
                node.physicsBody?.mass = CGFloat(mass)
                node.physicsBody?.friction = defaultFriction
                node.physicsBody?.restitution = defaultRestitution
                node.physicsBody?.categoryBitMask = 2
                node.physicsBody?.collisionBitMask = 1
                node.physicsBody?.contactTestBitMask = 1
            }
            
            // Set position if not already set
            if node.position.x == 0 && node.position.y == 0 && node.position.z == 0 {
                node.position = SCNVector3(
                    x: Float(position[0]),
                    y: Float(position[1]),
                    z: Float(position[2])
                )
            }
            
            // Set rendering order for occlusion
            node.renderingOrder = 1000
        }
        
        // Add to scene if not already added
        if physicsObjects[id] == nil {
            physicsObjects[id] = node
            arView.scene.rootNode.addChildNode(node)
        }
        
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
    
    /// Zoom in/out on the model using the given scale factor
    func zoomModel(scaleFactor: Double) -> Bool {
        guard let node = scannedNode else {
            return false
        }
        
        // Geçerli zoom aralığını kontrole et (çok büyük veya çok küçük olmasını engelle)
        let zoomFactor = Float(scaleFactor)
        let currentScale = node.scale
        
        // Minimum ve maksimum ölçek sınırları
        let minScale: Float = 0.1
        let maxScale: Float = 5.0
        
        // Yeni ölçeği hesapla
        let newScale = SCNVector3(
            x: currentScale.x * zoomFactor,
            y: currentScale.y * zoomFactor,
            z: currentScale.z * zoomFactor
        )
        
        // Ölçek sınırlarını kontrol et
        if newScale.x < minScale || newScale.y < minScale || newScale.z < minScale ||
           newScale.x > maxScale || newScale.y > maxScale || newScale.z > maxScale {
            print("PhysicsView: Zoom rejected - would exceed scale limits")
            return false
        }
        
        // Yeni ölçeği uygula
        node.scale = newScale
        print("PhysicsView: Model zoomed to scale: (\(newScale.x), \(newScale.y), \(newScale.z))")
        
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
    
    /// Set the selected object type for physics objects
    func setSelectedObject(type: String) -> Bool {
        print("PhysicsView: Setting selected object type to \(type)")
        selectedObjectType = type
        return true
    }
    
    /// Start object rain effect with the selected object type
    func startObjectRain(count: Int, height: Float) -> Bool {
        let cameraPos = arView.pointOfView?.position ?? SCNVector3(0, 0, 0)
        
        // Yağmur daha geniş bir alanda oluşsun
        let rainRadiusHorizontal: Float = 5.0  // Daha geniş yatay yayılım
        let rainHeight: Float = height + 1.0    // Biraz daha yüksekten
        
        print("PhysicsView: Starting object rain with \(count) \(selectedObjectType) objects")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            for i in 0..<count {
                // Kamera etrafında geniş alanda rastgele pozisyon
                let angle = Float.random(in: 0...(Float.pi * 2))  // 0-360 derece
                let distance = Float.random(in: 0.5...rainRadiusHorizontal)  // Uzaklık
                
                // Polar koordinatları x,z düzlemine çevir
                let randomX = cameraPos.x + cos(angle) * distance
                let randomZ = cameraPos.z + sin(angle) * distance
                
                // Yükseklik - daha rastgele
                let randomY = cameraPos.y + rainHeight + Float.random(in: -0.5...1.5)
                
                // Başlangıç hızı ve dönüş - her model tipi için farklı
                var initialVelocity = [
                    Double.random(in: -0.3...0.3),  // Rastgele x hızı
                    Double.random(in: -0.1...0.0),  // Hafif aşağı y hızı
                    Double.random(in: -0.3...0.3)   // Rastgele z hızı
                ]
                
                var initialAngularVelocity = [
                    Double.random(in: -2...2),  // x ekseni etrafında dönüş
                    Double.random(in: -2...2),  // y ekseni etrafında dönüş
                    Double.random(in: -2...2)   // z ekseni etrafında dönüş
                ]
                
                // Model tipine göre ayarlar
                var scale: [Double]
                var mass: Double
                var color: [Int]
                
                switch self.selectedObjectType {
                case "sphere":
                    scale = [Double.random(in: 0.02...0.06), 
                             Double.random(in: 0.02...0.06), 
                             Double.random(in: 0.02...0.06)]
                    mass = Double.random(in: 0.3...1.0)
                    
                    // Toplar için canlı renkler
                    color = [
                        Int.random(in: 100...255), // Daha canlı
                        Int.random(in: 100...255),
                        Int.random(in: 100...255),
                        255
                    ]
                    
                case "cube":
                    scale = [Double.random(in: 0.025...0.05), 
                             Double.random(in: 0.025...0.05), 
                             Double.random(in: 0.025...0.05)]
                    mass = Double.random(in: 1.0...1.5) // Küpler biraz daha ağır
                    
                    // Küpler için koyu renkler
                    color = [
                        Int.random(in: 50...200),
                        Int.random(in: 50...200),
                        Int.random(in: 50...200),
                        255
                    ]
                    
                case "cylinder":
                    scale = [Double.random(in: 0.025...0.04), 
                             Double.random(in: 0.04...0.08), // Yükseklik farklı
                             Double.random(in: 0.025...0.04)]
                    mass = Double.random(in: 0.6...1.2)
                    
                    // Silindirler için daha sakin renkler
                    color = [
                        Int.random(in: 70...180),
                        Int.random(in: 70...180),
                        Int.random(in: 70...220),
                        255
                    ]
                    
                case "coin":
                    // Coinler daha düzgün boyutlarda olsun
                    let coinSize = Double.random(in: 0.04...0.06)
                    scale = [coinSize, 0.008, coinSize]
                    mass = 1.0 
                    
                    // Altın veya Gümüş renk seçeneği
                    if Bool.random() { // %50 şans
                        // Altın
                        color = [215, 165, 25, 255]
                    } else {
                        // Gümüş
                        color = [192, 192, 192, 255]
                    }
                    
                    // Coinlerin daha düzgün düşmesi için başlangıç hızı
                    initialVelocity = [
                        Double.random(in: -0.1...0.1),
                        -0.05, // Sabit düşüş
                        Double.random(in: -0.1...0.1)
                    ]
                    
                    // Coinlere daha çok dönüş ver
                    initialAngularVelocity = [
                        Double.random(in: -0.5...0.5),
                        Double.random(in: -4...4),  // y ekseni etrafında daha hızlı dön
                        Double.random(in: -0.5...0.5)
                    ]
                    
                case "usdz":
                    scale = [0.01, 0.01, 0.01] // USDZ modelleri genellikle daha büyüktür
                    mass = Double.random(in: 0.5...1.5)
                    
                    // USDZ modeller için rastgele renk
                    color = [
                        Int.random(in: 50...255),
                        Int.random(in: 50...255),
                        Int.random(in: 50...255),
                        255
                    ]
                    
                default:
                    scale = [0.05, 0.05, 0.05] 
                    mass = 1.0
                    color = [
                        Int.random(in: 50...255),
                        Int.random(in: 50...255),
                        Int.random(in: 50...255),
                        255
                    ]
                }
                
                // Benzersiz ID oluştur
                let objectId = "rain_\(self.selectedObjectType)_\(i)_\(Date().timeIntervalSince1970)"
                
                // Obje datasını oluştur
                let objectData: [String: Any] = [
                    "id": objectId,
                    "type": self.selectedObjectType,
                    "position": [Double(randomX), Double(randomY), Double(randomZ)],
                    "scale": scale,
                    "color": color,
                    "mass": mass,
                    "velocity": initialVelocity,
                    "angularVelocity": initialAngularVelocity
                ]
                
                // Ana thread'de objeyi ekle
                DispatchQueue.main.async {
                    _ = self.addPhysicsObject(objectData: objectData)
                }
                
                // Tüm objelerin aynı anda spawn edilmemesi için delay
                if i % 3 == 0 {
                    Thread.sleep(forTimeInterval: 0.03)
                }
            }
        }
        
        return true
    }
    
    /// Confirm that LiDAR mesh occlusion is enabled in the AR configuration
    func confirmLiDAREnabled() {
        if let configuration = arView.session.configuration as? ARWorldTrackingConfiguration,
           ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            
            // Ensure mesh reconstruction is enabled
            if configuration.sceneReconstruction != .mesh {
                configuration.sceneReconstruction = .mesh
                
                print("PhysicsView: Re-enabling LiDAR mesh reconstruction")
                // Rerun with the proper configuration
                arView.session.run(configuration)
            } else {
                print("PhysicsView: LiDAR mesh reconstruction is already active")
            }
        } else {
            print("PhysicsView: Device does not support LiDAR mesh reconstruction")
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
        
        // Proper occlusion material configuration
        material.diffuse.contents = UIColor.clear // Invisible material
        material.colorBufferWriteMask = [] // Don't write to color buffer
        material.isDoubleSided = true
        material.writesToDepthBuffer = true // Write to depth buffer for occlusion
        material.readsFromDepthBuffer = false
        material.lightingModel = .constant // Not affected by lighting
        
        // Apply material to all geometry surfaces
        geometry.materials = [material]

        let node = SCNNode(geometry: geometry)
        node.renderingOrder = -100 // Render before everything else
        node.opacity = 1.0
        node.categoryBitMask = 4 // Special mask for occlusion only
        node.castsShadow = false
        node.transform = SCNMatrix4(meshAnchor.transform)

        // Add occlusion node to scene
        arView.scene.rootNode.addChildNode(node)
        
        print("Added mesh anchor for occlusion")
    }
} 