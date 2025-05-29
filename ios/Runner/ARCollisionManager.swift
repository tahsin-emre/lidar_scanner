import SceneKit
import ARKit

/// AR çarpışma yüzeylerini yöneten sınıf (düzlemler ve meshler)
class ARCollisionManager {
    // MARK: - Properties
    private var arView: ARSCNView
    
    // MARK: - Initialization
    init(arView: ARSCNView) {
        self.arView = arView
    }
    

    func toggleOcclusionQuality(isHighQuality: Bool) {
        if isHighQuality {
            // Yüksek kalite oklüzyon modu
            // Sadece rootNode ve çocuklarına renderingOrder uygula
            arView.scene.rootNode.renderingOrder = -1
            
            // Tüm oklüzyon nodlarını yeniden render sırasını ayarla
            arView.scene.rootNode.enumerateChildNodes { (node, _) in
                // Oklüzyon mesh nodları için ek ayarlar
                if node.name?.contains("occlusion") == true || node.physicsBody?.categoryBitMask == 1 {
                    node.renderingOrder = -1
                }
            }
            
            print("ARCollisionManager: High quality occlusion enabled")
        } else {
            // Performans modu - daha az kesin oklüzyon ama daha iyi performans
            // Sadece rootNode ve çocuklarına renderingOrder uygula
            arView.scene.rootNode.renderingOrder = 0
            
            // Tüm nodlar için normal render sırası
            arView.scene.rootNode.enumerateChildNodes { (node, _) in
                node.renderingOrder = 0
            }
            
            print("ARCollisionManager: Normal quality occlusion (better performance)")
        }
        
        // Oklüzyon Hata Ayıklama: Sorunları belirlemek için geçici olarak düzlemleri görünür yap
        let showDebugVisuals = false // Sadece geliştirme için true yapın
        if showDebugVisuals {
            arView.debugOptions = [.showPhysicsShapes]
        } else {
            arView.debugOptions = []
        }
    }
    
    func addPlaneIndicator() {
        let planeIndicator = SCNNode()
        let plane = SCNPlane(width: 0.1, height: 0.1)
        plane.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
        plane.firstMaterial?.isDoubleSided = true
        planeIndicator.geometry = plane
        planeIndicator.eulerAngles.x = -.pi / 2
        planeIndicator.opacity = 0.6
        planeIndicator.name = "planeIndicator"
        arView.scene.rootNode.addChildNode(planeIndicator)
        planeIndicator.isHidden = true
    }
    
    func addCollisionPlane(for planeAnchor: ARPlaneAnchor, to node: SCNNode) {

        var isFloor = false
        var floorConfidence: Float = 0.0
        if planeAnchor.alignment == .horizontal {
            let minimumFloorSize: Float = 0.2 // Minimum 0.5m x 0.5m
            if planeAnchor.extent.x > minimumFloorSize && planeAnchor.extent.z > minimumFloorSize {
                floorConfidence += 0.3
            }

            let cameraHeight = getCameraHeight()
            if planeAnchor.transform.columns.3.y < (cameraHeight - 0.5) {
                floorConfidence += 0.4
            }
            
            let normalY = abs(planeAnchor.transform.columns.1.y)
            if normalY > 0.95 {
                floorConfidence += 0.3
            }

            isFloor = floorConfidence > 0.5
        }
        
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), 
                            height: CGFloat(planeAnchor.extent.z))
        

        let collisionNode = SCNNode(geometry: plane)
        collisionNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        collisionNode.eulerAngles.x = -.pi / 2
        collisionNode.opacity = 0.0
        let physicsShape = SCNPhysicsShape(geometry: plane, options: nil)
        collisionNode.physicsBody = SCNPhysicsBody(
            type: .static, 
            shape: physicsShape
        )
        collisionNode.physicsBody?.categoryBitMask = 1 
        collisionNode.physicsBody?.collisionBitMask = 2 

        if isFloor {
            collisionNode.physicsBody?.friction = 0.8 
            collisionNode.physicsBody?.restitution = 0.2
            collisionNode.name = "floor_collision_\(planeAnchor.identifier.uuidString)"
        } else {
            collisionNode.physicsBody?.friction = 0.5
            collisionNode.physicsBody?.restitution = 0.5
            collisionNode.name = "plane_collision_\(planeAnchor.identifier.uuidString)"
        }
        
        node.addChildNode(collisionNode)
        
        let occlusionPlane = SCNPlane(width: CGFloat(planeAnchor.extent.x), 
                                    height: CGFloat(planeAnchor.extent.z))
        let occlusionNode = SCNNode(geometry: occlusionPlane)
        occlusionNode.name = isFloor 
            ? "occlusion_floor_\(planeAnchor.identifier.uuidString)"
            : "occlusion_plane_\(planeAnchor.identifier.uuidString)"
        
        occlusionNode.position = collisionNode.position
        occlusionNode.eulerAngles = collisionNode.eulerAngles
        
        let occlusionMaterial = SCNMaterial()

        occlusionMaterial.lightingModel = .constant
        occlusionMaterial.diffuse.contents = UIColor.black
        occlusionMaterial.colorBufferWriteMask = []
        occlusionMaterial.writesToDepthBuffer = true 
        occlusionMaterial.readsFromDepthBuffer = true
        occlusionMaterial.isDoubleSided = true
        occlusionMaterial.transparencyMode = .aOne
        occlusionMaterial.blendMode = .alpha

        if #available(iOS 13.0, *) {
            let depthBiasValue: Float = isFloor ? 0.0003 : 0.0004
            occlusionMaterial.setValue(NSNumber(value: depthBiasValue), forKey: "depthBias")
            occlusionMaterial.setValue(NSNumber(value: 3), forKey: "depthFunction")
        }
        occlusionNode.geometry?.firstMaterial = occlusionMaterial
        node.addChildNode(occlusionNode)
    }
    
    /// Mesh için çarpışma ve oklüzyon ekleme
    @available(iOS 13.4, *)
    func addCollisionMesh(for meshAnchor: ARMeshAnchor, to node: SCNNode) {
        // Eğer ARKit 3.5 ve üstü (LiDAR) ise mesh collision ekle
        let geometry = SCNGeometry(arGeometry: meshAnchor.geometry)
        
        // ---- FİZİK ÇARPIŞMASI İÇİN MESH NODE ----
        // Fizik çarpışmaları için görünmez bir mesh node oluştur
        let collisionNode = SCNNode(geometry: geometry)
        
        // Fizik node'unu tamamen görünmez yap
        collisionNode.opacity = 0.0
        
        // Statik fizik gövdesi ekle (hareket etmeyecek)
        collisionNode.physicsBody = SCNPhysicsBody(type: .static, 
                                            shape: SCNPhysicsShape(geometry: geometry, 
                                                                options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        
        // Çarpışma kategorisi ve maskeleme ayarla
        collisionNode.physicsBody?.categoryBitMask = 1 // Gerçek dünya kategorisi
        collisionNode.physicsBody?.collisionBitMask = 2 // AR objeleri ile çarpışabilir
        
        // Ana node'a fizik çarpışması için node ekle
        node.addChildNode(collisionNode)
        
        // ---- OKLÜZYON (OCCLUSION) İÇİN MESH NODE ----
        // Oklüzyon etkisi için ikinci bir mesh node oluştur
        let occlusionNode = SCNNode(geometry: geometry.copy() as! SCNGeometry)
        
        // Oklüzyon mesh noduna özel isim ver
        occlusionNode.name = "occlusion_mesh_\(meshAnchor.identifier.uuidString)"
        
        // Gelişmiş mesh oklüzyon materyali
        let occlusionMaterial = SCNMaterial()

        // Ana ayarlar - Tamamen siyah ve ışık almayan materyal
        occlusionMaterial.lightingModel = .constant 
        occlusionMaterial.diffuse.contents = UIColor.black

        // İYİLEŞTİRİLMİŞ MESH OKLÜZYON: Daha kararlı görünürlük
        occlusionMaterial.colorBufferWriteMask = [] // Renk bufferına yazma
        occlusionMaterial.writesToDepthBuffer = true // Derinlik tamponuna yaz
        
        // SORUN ÇÖZME: Mesh oklüzyon kararsızlığını gidermek için
        occlusionMaterial.readsFromDepthBuffer = true // Derinlik tamponundan OKUMA aktif
        
        // Mesh için ek ayarlar
        occlusionMaterial.isDoubleSided = true // Çift taraflı - daha iyi kapsama
        occlusionMaterial.transparencyMode = .aOne // A-One transparanlık modu
        occlusionMaterial.blendMode = .alpha // Alpha blending

        // Z-fighting sorunlarını önlemek için daha düşük depthBias değeri
        if #available(iOS 13.0, *) {
            // Mesh için daha küçük değer kullan
            occlusionMaterial.setValue(NSNumber(value: 0.0004), forKey: "depthBias")
            
            // Derinlik tamponu karşılaştırma fonksiyonu
            occlusionMaterial.setValue(NSNumber(value: 3), forKey: "depthFunction") // SCNCompareFunction.less = 3
            
            // Mesh'in alpha eşiğini ayarla - daha kesin oklüzyon sınırları
            occlusionMaterial.setValue(NSNumber(value: 0.1), forKey: "alphaTest")
        }
        
        // Tüm mesh yüzeylerine oklüzyon materyali uygula
        for i in 0..<occlusionNode.geometry!.materials.count {
            occlusionNode.geometry?.replaceMaterial(at: i, with: occlusionMaterial)
        }
        
        // Ana node'a oklüzyon için node ekle
        node.addChildNode(occlusionNode)
        
        print("ARCollisionManager: Added collision and occlusion mesh for anchor \(meshAnchor)")
    }
    
    // MARK: - Private Methods
    
    /// Kamera yüksekliğini döndürür
    private func getCameraHeight() -> Float {
        guard let currentFrame = arView.session.currentFrame else {
            // Varsayılan değer
            return 1.6 // Ortalama insan boyu (m)
        }
        
        let cameraTransform = currentFrame.camera.transform
        return cameraTransform.columns.3.y
    }
} 