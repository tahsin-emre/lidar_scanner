import Flutter
import UIKit
import ARKit
import SceneKit

/// Tarama ile eşzamanlı olarak AR objeleri yerleştirmek için görünüm
class ARPhysicsView: NSObject, FlutterPlatformView, ARSCNViewDelegate {
    // MARK: - Properties
    private var arView: ARSCNView!
    private let session = ARSession()
    
    private var physicsScene: SCNPhysicsWorld {
        return arView.scene.physicsWorld
    }
    
    private var physicsObjects = [String: SCNNode]()
    private var lastFrameTime: TimeInterval = 0
    private var frameCount = 0
    private var currentFps: Double = 0
    
    private var gravity: Float = -9.8
    private var defaultFriction: CGFloat = 0.5
    private var defaultRestitution: CGFloat = 0.4
    
    private var showDebugVisualization: Bool = false
    
    private var selectedObjectType: String = "sphere"
    
    // MARK: - Initialization
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        super.init()
        
        // AR görünümünü ayarla
        arView = ARSCNView(frame: frame)
        arView.delegate = self
        arView.session = session
        arView.autoenablesDefaultLighting = true
        arView.automaticallyUpdatesLighting = true
        
        // Debug görselleştirmelerini tamamen kaldır
        arView.debugOptions = []
        
        // Derinlik testi ve oklüzyon ayarları
        arView.scene.rootNode.renderingOrder = -1 // Önce render et
        
        // Oklüzyon kalitesini artırmak için ek ayarlar
        if #available(iOS 13.0, *) {
            // Metal renderlarken daha kaliteli oklüzyon için
            arView.antialiasingMode = .multisampling4X
            
            // Tercih edilen FPS değeri - SCNView üzerinden ayarla
            arView.preferredFramesPerSecond = 60
        }
        
        // Fizik simülasyonu yerçekimini ayarla
        arView.scene.physicsWorld.gravity = SCNVector3(0, -9.8, 0)
        
        // Titreşimi azaltmak için fizik simülasyonu parametrelerini ayarla
        arView.scene.physicsWorld.timeStep = 1.0/120.0 // Daha yüksek fizik simülasyon hızı
        arView.scene.physicsWorld.speed = 1.0 // Normal hız
        
        print("ARPhysicsView: Initialized with frame \(frame)")
        
        // Metodları Flutter'a kaydet
        registerMethodChannel(messenger: messenger, viewId: viewId)
        
        // AR oturumunu başlat
        startARSession()
        
        // Yüksek kaliteli oklüzyon modunu aktif et
        toggleOcclusionQuality(isHighQuality: true)
    }
    
    // MARK: - Public methods
    func view() -> UIView {
        print("ARPhysicsView: Returning ARView instance")
        return arView
    }
    
    // MARK: - Private methods
    private func startARSession() {
        let configuration = ARWorldTrackingConfiguration()
        
        // ARKit konfigürasyonunu ULTİMATE TARAMA KALİTESİNE ayarla
        
        // Zemin ve düzlem algılama özelliklerini maksimuma çıkar
        configuration.planeDetection = [.horizontal, .vertical]
        
        // LiDAR destekli cihazlarda ek özellikler
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            print("ARPhysicsView: Device supports LiDAR mesh reconstruction")
            
            // Tam mesh yeniden yapılandırma - ULTİMATE kalite
            configuration.sceneReconstruction = .mesh // Standart mesh
            
            // Zemin algılama hassasiyetini artır
            if #available(iOS 13.4, *) {
                // LiDAR tarayıcıya özgü zemin algılama optimizasyonları
                configuration.isAutoFocusEnabled = true // Daha net scene taraması
                
                // Scene derinlik haritası kalitesini artır
                if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
                    configuration.frameSemantics.insert(.smoothedSceneDepth)
                    print("ARPhysicsView: Enhanced depth quality enabled for floor detection")
                }
                
                // Daha yüksek kaliteli çevre haritalama
                configuration.environmentTexturing = .automatic
                
                // İnsan segmentasyonu ile zeminlerin daha iyi ayrılması
                if #available(iOS 13.0, *) {
                    if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentation) {
                        configuration.frameSemantics.insert(.personSegmentation)
                        print("ARPhysicsView: Person segmentation enabled - better floor detection")
                    }
                }
            }
            
            // Mutlak konum modelini maksimum hassasiyete ayarla
            if #available(iOS 14.0, *) {
                if ARWorldTrackingConfiguration.supportsAppClipCodeTracking {
                    // Daha hassas konum izleme için gelişmiş modeli kullan
                    print("ARPhysicsView: Enhanced position tracking enabled")
                }
            }
            
            print("ARPhysicsView: ULTIMATE LiDAR scanning enabled for floor detection")
        } else {
            print("ARPhysicsView: Device does NOT support LiDAR - using standard detection")
            
            // Çevre aydınlatmasını etkinleştir - daha iyi düzlem tespiti için
            configuration.environmentTexturing = .automatic
            
            // LiDAR olmayan cihazlarda genişletilmiş düzlem algılama
            if #available(iOS 12.0, *) {
                configuration.maximumNumberOfTrackedImages = 0 // Düzlem tespitine odaklanmak için
                configuration.detectionImages = nil
                
                // Zemin algılama için ışık tahmini
                configuration.isLightEstimationEnabled = true
            }
        }
        
        // ARKit kalite ayarları
        if #available(iOS 13.0, *) {
            session.delegateQueue = DispatchQueue.global(qos: .userInteractive) // En hızlı işlem için
        }
        
        // Oturumu RESET ile başlat (tam temiz bir tarama için)
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors, .resetSceneReconstruction])
        print("ARPhysicsView: AR Session started with ULTIMATE floor detection configuration")
        
        // Düzlem algılama için gösterge nodunu ekle
        addPlaneIndicator()
    }
    
    // Düzlem algılama için gösterge ekle
    private func addPlaneIndicator() {
        let planeIndicator = SCNNode()
        
        // Düzlem göstergesi olarak kullanacağımız basit bir düzlem geometrisi
        let plane = SCNPlane(width: 0.1, height: 0.1)
        plane.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
        plane.firstMaterial?.isDoubleSided = true
        
        planeIndicator.geometry = plane
        planeIndicator.eulerAngles.x = -.pi / 2
        planeIndicator.opacity = 0.6
        planeIndicator.name = "planeIndicator"
        
        arView.scene.rootNode.addChildNode(planeIndicator)
        
        // İlk başta göstergeyi gizle
        planeIndicator.isHidden = true
        
        print("ARPhysicsView: Added plane indicator")
    }
    
    // MARK: - ARSCNViewDelegate Methods
    
    // Yeni bir anchor eklendiğinde
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            print("ARPhysicsView: Plane detected at \(planeAnchor.transform)")
            addCollisionPlane(for: planeAnchor, to: node)
        } else if let meshAnchor = anchor as? ARMeshAnchor {
            print("ARPhysicsView: Mesh detected")
            addCollisionMesh(for: meshAnchor, to: node)
        }
    }
    
    // Anchor güncellendiğinde - yüksek kaliteli takip
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            print("ARPhysicsView: Plane updated: \(planeAnchor.identifier.uuidString)")
            
            // Düzlemin genişliği belirli bir eşiğin üstündeyse güncelle
            // Bu, hızlı küçük güncellemelerde gereksiz yeniden işlemleri önler
            let significantChange = planeAnchor.extent.x > 0.05 || planeAnchor.extent.z > 0.05
            
            if significantChange {
                // Önemli değişiklikleri günlüğe kaydet
                print("ARPhysicsView: Significant plane update - new dimensions: \(planeAnchor.extent)")
                
                // Mevcut collision plane'i kaldır
                node.childNodes.forEach { $0.removeFromParentNode() }
                
                // Yeni collision plane ekle
                addCollisionPlane(for: planeAnchor, to: node)
            }
            
        } else if let meshAnchor = anchor as? ARMeshAnchor {
            print("ARPhysicsView: Mesh updated: \(meshAnchor.identifier.uuidString)")
            
            // Mevcut çakışma meshini kaldır
            node.childNodes.forEach { $0.removeFromParentNode() }
            
            // Yeni çakışma meshi ekle
            addCollisionMesh(for: meshAnchor, to: node)
            
            // Mesh kalitesi bilgisini yazdır (debug için)
            print("ARPhysicsView: Mesh updated with high quality")
        }
    }
    
    // Anchor kaldırıldığında
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            print("ARPhysicsView: Plane removed")
        } else if anchor is ARMeshAnchor {
            print("ARPhysicsView: Mesh removed")
        }
    }
    
    // Her kare işlendiğinde
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // FPS hesapla
        if lastFrameTime == 0 {
            lastFrameTime = time
            frameCount = 0
        } else if time - lastFrameTime >= 1.0 {
            currentFps = Double(frameCount) / (time - lastFrameTime)
            frameCount = 0
            lastFrameTime = time
        }
        frameCount += 1
    }
    
    // MARK: - Collision Handling Methods
    
    // Tespit edilen düzlemler için yüksek kaliteli collision node oluşturma
    private func addCollisionPlane(for planeAnchor: ARPlaneAnchor, to node: SCNNode) {
        // Düzlem bilgilerini loglayarak kaliteyi kontrol et
        print("ARPhysicsView: Detected plane with dimensions: \(planeAnchor.extent) at position: \(planeAnchor.center)")
        
        // Basit düzlem bilgilerini göster
        if #available(iOS 13.0, *) {
            print("ARPhysicsView: High quality plane detected")
        }
        
        // ULTİMATE ZEMİN ALGILIAMA - Düzlemin gerçekten zemin olup olmadığını belirle
        var isFloor = false
        var floorConfidence: Float = 0.0
        
        // Zemin tespiti için kriterler
        if planeAnchor.alignment == .horizontal {
            // 1. Düzlem genişliği kriterine göre - geniş düzlemler genellikle zemindir
            let minimumFloorSize: Float = 0.5 // Minimum 0.5m x 0.5m
            if planeAnchor.extent.x > minimumFloorSize && planeAnchor.extent.z > minimumFloorSize {
                floorConfidence += 0.3
            }
            
            // 2. Y-pozisyonu kriterine göre - zemin genellikle en alttaki düzlemdir
            let cameraHeight = getCameraHeight()
            if planeAnchor.transform.columns.3.y < (cameraHeight - 0.5) {
                floorConfidence += 0.4
            }
            
            // 3. Düzlemin düzlüğü (normal vektörünün y-yönünün büyüklüğü)
            let normalY = abs(planeAnchor.transform.columns.1.y)
            if normalY > 0.95 { // Neredeyse tam olarak düz
                floorConfidence += 0.3
            }
            
            // Zemin olma olasılığını belirle
            isFloor = floorConfidence > 0.5
            
            if isFloor {
                print("ARPhysicsView: FLOOR DETECTED with confidence: \(floorConfidence)")
            }
        }
        
        // Algılanan düzlem boyutlarında bir düzlem geometrisi oluştur - kesin boyutlar
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), 
                           height: CGFloat(planeAnchor.extent.z))
        
        // ----- FİZİK ÇARPIŞMASI İÇİN DÜZLEM NODE -----
        
        // Collision için bir düzlem nodu oluştur
        let collisionNode = SCNNode(geometry: plane)
        
        // Düzlemi doğru pozisyona getir
        collisionNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // Düzlemi yatay olarak konumlandır (X rotasyonu -90 derece)
        collisionNode.eulerAngles.x = -.pi / 2
        
        // Düzlemi görünmez yap ama fizik collision'ı etkinleştir
        collisionNode.opacity = 0.0
        
        // Zemin ise daha sabit fizik özellikleri kullan
        let physicsShape = SCNPhysicsShape(geometry: plane, options: nil)
        collisionNode.physicsBody = SCNPhysicsBody(
            type: .static, 
            shape: physicsShape
        )
        
        // Çarpışma kategorisi ve maskeleme ayarla
        collisionNode.physicsBody?.categoryBitMask = 1 // Düzlem kategorisi
        collisionNode.physicsBody?.collisionBitMask = 2 // AR objeleri ile çarpışabilir
        
        // Fiziksel özellikler - zemin için optimize edilmiş
        if isFloor {
            // Zemin için özel fizik özellikleri
            collisionNode.physicsBody?.friction = 0.8 // Yüksek sürtünme
            collisionNode.physicsBody?.restitution = 0.2 // Düşük zıplama - düşen objeler yerinde kalsın
            
            // Özel isimlendirme
            collisionNode.name = "floor_collision_\(planeAnchor.identifier.uuidString)"
        } else {
            // Diğer düzlemler için normal değerler
            collisionNode.physicsBody?.friction = 0.5
            collisionNode.physicsBody?.restitution = 0.5
            
            collisionNode.name = "plane_collision_\(planeAnchor.identifier.uuidString)"
        }
        
        // Düzlem nodesine çarpışma node'unu ekle
        node.addChildNode(collisionNode)
        
        // ----- OKLÜZYON (OCCLUSION) İÇİN DÜZLEM NODE -----
        
        // Oklüzyon etkisi için ikinci bir düzlem node oluştur - kesin boyutlar
        let occlusionPlane = SCNPlane(width: CGFloat(planeAnchor.extent.x), 
                                    height: CGFloat(planeAnchor.extent.z))
        let occlusionNode = SCNNode(geometry: occlusionPlane)
        
        // Oklüzyon noduna özel isim ver
        occlusionNode.name = isFloor 
            ? "occlusion_floor_\(planeAnchor.identifier.uuidString)"
            : "occlusion_plane_\(planeAnchor.identifier.uuidString)"
        
        // Aynı pozisyon ve rotasyonu kullan
        occlusionNode.position = collisionNode.position
        occlusionNode.eulerAngles = collisionNode.eulerAngles
        
        // Gelişmiş oklüzyon materyali (z-fighting sorunlarını gidermek için)
        let occlusionMaterial = SCNMaterial()

        // Ana ayarlar - Tamamen siyah ve ışık almayan materyal
        occlusionMaterial.lightingModel = .constant
        occlusionMaterial.diffuse.contents = UIColor.black

        // ÖNEMLİ GÜNCELLEME: Kararlı oklüzyon için düzlem düzlemlerin derinlik tamponu ile ilişkisi
        occlusionMaterial.colorBufferWriteMask = [] // Renk bufferına yazma
        occlusionMaterial.writesToDepthBuffer = true // Derinlik tamponuna yaz
        
        // SORUN ÇÖZME: Oklüzyon kararsızlığını gidermek için
        // Daha önceki değerden (false) farklı olarak, depth buffer'dan okumayı etkinleştir
        // Bu, AR objelerinin sihirli bir şekilde görünüp kaybolmasını önler
        occlusionMaterial.readsFromDepthBuffer = true

        // Düzlemler için ek ayarlar - daha yüksek kararlılık
        occlusionMaterial.isDoubleSided = true // Çift taraflı görünürlük
        occlusionMaterial.transparencyMode = .aOne // A-One transparanlık modu
        occlusionMaterial.blendMode = .alpha // Alpha blending modu oklüzyon için daha uygundur

        // Z-fighting sorunları için derinlik ofset ayarları - daha küçük değer kullan
        if #available(iOS 13.0, *) {
            // Zemin için daha küçük bir ofset (daha doğru oklüzyon)
            let depthBiasValue: Float = isFloor ? 0.0003 : 0.0004
            occlusionMaterial.setValue(NSNumber(value: depthBiasValue), forKey: "depthBias")
            
            // Derinlik tamponu karşılaştırma fonksiyonu
            // lequal yerine less kullanıldığında, bulanık oklüzyon kenarları azalır
            occlusionMaterial.setValue(NSNumber(value: 3), forKey: "depthFunction") // SCNCompareFunction.less = 3
        }
        
        // Materyal uygula
        occlusionNode.geometry?.firstMaterial = occlusionMaterial
        
        // Ana node'a oklüzyon node'unu ekle
        node.addChildNode(occlusionNode)
        
        if isFloor {
            print("ARPhysicsView: ✓✓✓ ADDED HIGH QUALITY FLOOR with size \(planeAnchor.extent), confidence: \(floorConfidence)")
        } else {
            print("ARPhysicsView: Added collision and occlusion plane with size \(planeAnchor.extent)")
        }
    }
    
    // Tespit edilen mesh'ler için collision node oluşturma
    private func addCollisionMesh(for meshAnchor: ARMeshAnchor, to node: SCNNode) {
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
        
        print("ARPhysicsView: Added collision and occlusion mesh for anchor \(meshAnchor)")
    }
    
    private func convertScreenToWorldPosition(x: Double, y: Double, result: @escaping FlutterResult) {
        let point = CGPoint(x: x, y: y)
        print("ARPhysicsView: Converting screen position \(point) to world position")
        
        // 1. Gerçek yüzeyleri dokunma noktasından hit-test ile kontrol et
        let hitTestResults = arView.hitTest(point, types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane, .estimatedVerticalPlane])
        
        // 2. Özellikle tespit edilmiş düzlemlere öncelik ver
        if let hitTestResult = hitTestResults.first {
            // Hit test ile bulunan pozisyon (gerçek dünya yüzeyinde)
            let hitPosition = SCNVector3(
                hitTestResult.worldTransform.columns.3.x,
                hitTestResult.worldTransform.columns.3.y,
                hitTestResult.worldTransform.columns.3.z
            )
            
            print("ARPhysicsView: Hit test found surface at: \(hitPosition)")
            
            // Biraz yüzeyin üstüne konumla (yerçekimi ile düşmesi için)
            let finalPosition = SCNVector3(
                hitPosition.x,
                hitPosition.y + 0.1, // Yüzeyin 10cm üzerinde
                hitPosition.z
            )
            
            result([
                Double(finalPosition.x),
                Double(finalPosition.y),
                Double(finalPosition.z)
            ])
            
            // Update the indicator position
            if let planeIndicator = arView.scene.rootNode.childNode(withName: "planeIndicator", recursively: true) {
                planeIndicator.position = hitPosition
                planeIndicator.isHidden = false
            }
            
            return
        }
        
        // 3. Eğer bir yüzey bulunamazsa, kameranın bakış yönünde bir noktaya yerleştir
        let raycastQuery = arView.raycastQuery(from: point, allowing: .estimatedPlane, alignment: .any)
        
        if let query = raycastQuery, let raycastResult = arView.session.raycast(query).first {
            let rayPosition = SCNVector3(
                raycastResult.worldTransform.columns.3.x,
                raycastResult.worldTransform.columns.3.y,
                raycastResult.worldTransform.columns.3.z
            )
            
            print("ARPhysicsView: Raycast found point at: \(rayPosition)")
            
            result([
                Double(rayPosition.x),
                Double(rayPosition.y),
                Double(rayPosition.z)
            ])
            
            // Update the indicator position
            if let planeIndicator = arView.scene.rootNode.childNode(withName: "planeIndicator", recursively: true) {
                planeIndicator.position = rayPosition
                planeIndicator.isHidden = false
            }
            
            return
        }
        
        // 4. Son çare: Kamera önünde bir pozisyon
        let cameraPosition = getPositionInFrontOfCamera(distance: 0.5)
        print("ARPhysicsView: Fallback to position in front of camera: \(cameraPosition)")
        
        result([
            Double(cameraPosition.x),
            Double(cameraPosition.y),
            Double(cameraPosition.z)
        ])
        
        // Update the indicator position
        if let planeIndicator = arView.scene.rootNode.childNode(withName: "planeIndicator", recursively: true) {
            planeIndicator.position = cameraPosition
            planeIndicator.isHidden = false
        }
    }
    
    private func getPositionInFrontOfCamera(distance: Float) -> SCNVector3 {
        guard let currentFrame = arView.session.currentFrame else {
            print("ARPhysicsView: No current frame available")
            // Default position if no frame
            return SCNVector3(0, 0, -distance)
        }
        
        let camera = currentFrame.camera
        let cameraTransform = camera.transform
        
        let cameraPosition = SCNVector3(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        
        // Get the camera's forward direction (negative z-axis)
        let cameraDirection = SCNVector3(
            -cameraTransform.columns.2.x,
            -cameraTransform.columns.2.y,
            -cameraTransform.columns.2.z
        )
        
        // Position the object in front of the camera
        let positionInFrontOfCamera = SCNVector3(
            cameraPosition.x + cameraDirection.x * distance,
            cameraPosition.y + cameraDirection.y * distance,
            cameraPosition.z + cameraDirection.z * distance
        )
        
        return positionInFrontOfCamera
    }
    
    // Kameranın Y pozisyonunu döndürür (zemin tespiti için)
    private func getCameraHeight() -> Float {
        guard let currentFrame = arView.session.currentFrame else {
            // Varsayılan değer
            return 1.6 // Ortalama insan boyu (m)
        }
        
        let cameraTransform = currentFrame.camera.transform
        return cameraTransform.columns.3.y
    }
    
    // MARK: - Flutter Method Channel
    private func registerMethodChannel(messenger: FlutterBinaryMessenger?, viewId: Int64) {
        guard let messenger = messenger else { return }
        
        let channelName = "com.example.lidarScanner/arPhysics_\(viewId)"
        print("ARPhysicsView: Registering method channel: \(channelName)")
        
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: messenger
        )
        
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            print("ARPhysicsView: Received method call: \(call.method)")
            
            switch call.method {
            case "addPhysicsObject":
                if let args = call.arguments as? [String: Any],
                   let objectData = args["object"] as? [String: Any] {
                    self.addPhysicsObject(objectData: objectData, result: result)
                } else {
                    print("ARPhysicsView: Invalid arguments for addPhysicsObject")
                    result(FlutterError(code: "INVALID_ARGS", 
                                      message: "Invalid arguments for addPhysicsObject", 
                                      details: nil))
                }
                
            case "removePhysicsObject":
                if let args = call.arguments as? [String: Any],
                   let objectId = args["objectId"] as? String {
                    self.removePhysicsObject(id: objectId, result: result)
                } else {
                    print("ARPhysicsView: Invalid arguments for removePhysicsObject")
                    result(FlutterError(code: "INVALID_ARGS", 
                                      message: "Invalid arguments for removePhysicsObject", 
                                      details: nil))
                }
                
            case "clearPhysicsObjects":
                self.clearAllObjects()
                result(true)
                
            case "screenToWorldPosition":
                if let args = call.arguments as? [String: Any],
                   let x = args["x"] as? Double,
                   let y = args["y"] as? Double {
                    print("ARPhysicsView: Converting screen position: (\(x), \(y))")
                    self.convertScreenToWorldPosition(x: x, y: y, result: result)
                } else {
                    print("ARPhysicsView: Invalid arguments for screenToWorldPosition")
                    result(FlutterError(code: "INVALID_ARGS", 
                                      message: "Invalid arguments for screenToWorldPosition", 
                                      details: nil))
                }
                
            case "setPhysicsParameters":
                if let args = call.arguments as? [String: Any] {
                    self.setPhysicsParameters(args: args, result: result)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", 
                                      message: "Invalid arguments for setPhysicsParameters", 
                                      details: nil))
                }
                
            case "getFps":
                result(self.currentFps)
                
            default:
                print("ARPhysicsView: Method not implemented: \(call.method)")
                result(FlutterMethodNotImplemented)
            }
        }
        
        print("ARPhysicsView: Method channel registered")
    }
    
    // MARK: - AR Physics Object Methods
    private func addPhysicsObject(objectData: [String: Any], result: @escaping FlutterResult) {
        guard let id = objectData["id"] as? String,
              let type = objectData["type"] as? String,
              let position = objectData["position"] as? [Double],
              let colorArray = objectData["color"] as? [Int] else {
            print("ARPhysicsView: Missing required parameters for adding physics object")
            result(false)
            return
        }
        
        guard position.count >= 3 else {
            print("ARPhysicsView: Position array must have at least 3 elements")
            result(false)
            return
        }
        
        print("ARPhysicsView: Adding \(type) at position \(position)")
        
        // Convert position to SCNVector3
        let objectPosition = SCNVector3(
            Float(position[0]),
            Float(position[1]),
            Float(position[2])
        )
        
        // Objeyi oluştur
        var geometry: SCNGeometry
        var node: SCNNode
        
        switch type {
        case "sphere":
            geometry = SCNSphere(radius: 0.05)
            node = SCNNode(geometry: geometry)
            
            // Özel materyal oluştur
            let material = SCNMaterial()
            material.diffuse.contents = UIColor(
                red: CGFloat(colorArray[0]) / 255.0,
                green: CGFloat(colorArray[1]) / 255.0,
                blue: CGFloat(colorArray[2]) / 255.0,
                alpha: colorArray.count > 3 ? CGFloat(colorArray[3]) / 255.0 : 1.0
            )
            
            material.specular.contents = UIColor.white
            material.shininess = 0.5
            geometry.materials = [material]
            
            // Fizik özelliklerini ayarla - gerçek dünya ile etkileşim için
            node.physicsBody = SCNPhysicsBody(
                type: .dynamic,
                shape: SCNPhysicsShape(
                    geometry: geometry,
                    options: [
                        SCNPhysicsShape.Option.collisionMargin: 0.005, // Daha küçük çarpışma marjı
                        SCNPhysicsShape.Option.keepAsCompound: true // Kararlılık için
                    ]
                )
            )
            
            node.physicsBody?.mass = 1.0
            node.physicsBody?.restitution = 0.7 // Biraz daha az zıplama
            node.physicsBody?.friction = 0.5 // Daha fazla sürtünme
            node.physicsBody?.rollingFriction = 0.3 // Daha fazla yuvarlanma direnci
            
            // Fizik kararlılığı için damping ekle
            node.physicsBody?.damping = 0.1  // Lineer hareket sönümlemesi
            node.physicsBody?.angularDamping = 0.2  // Açısal hareket sönümlemesi
            
            // Çarpışma maskeleri - gerçek dünya ile etkileşim
            node.physicsBody?.categoryBitMask = 2 // AR obje kategorisi
            node.physicsBody?.collisionBitMask = 1 | 2 // Hem gerçek dünya (1) hem de diğer AR objelerle (2) çarpışabilir
            
            // Daha az rastgele dönüş hareketi (daha kararlı olması için)
            node.physicsBody?.angularVelocity = SCNVector4(
                Float.random(in: -0.5...0.5),
                Float.random(in: -0.5...0.5),
                Float.random(in: -0.5...0.5),
                Float.random(in: 0...2)
            )
            
        case "cube":
            geometry = SCNBox(
                width: 0.1,
                height: 0.1,
                length: 0.1,
                chamferRadius: 0.001 // Hafif yuvarlatılmış kenarlar
            )
            node = SCNNode(geometry: geometry)
            
            // Materyal oluştur
            let cubeMaterial = SCNMaterial()
            cubeMaterial.diffuse.contents = UIColor(
                red: CGFloat(colorArray[0]) / 255.0,
                green: CGFloat(colorArray[1]) / 255.0,
                blue: CGFloat(colorArray[2]) / 255.0,
                alpha: colorArray.count > 3 ? CGFloat(colorArray[3]) / 255.0 : 1.0
            )
            cubeMaterial.specular.contents = UIColor.white
            cubeMaterial.shininess = 0.3
            
            // Tüm yüzlere aynı materyali uygula
            node.geometry?.materials = Array(repeating: cubeMaterial, count: 6)
            
            // Fizik özelliklerini ayarla - gerçek dünya ile etkileşim için
            node.physicsBody = SCNPhysicsBody(
                type: .dynamic,
                shape: SCNPhysicsShape(
                    geometry: geometry,
                    options: [SCNPhysicsShape.Option.collisionMargin: 0.01]
                )
            )
            
            node.physicsBody?.mass = 2.0 // Küreden daha ağır
            node.physicsBody?.restitution = 0.4 // Orta zıplama katsayısı
            node.physicsBody?.friction = 0.8 // Yüksek sürtünme
            node.physicsBody?.rollingFriction = 0.5 // Yuvarlanma direnci yüksek
            
            // Çarpışma maskeleri - gerçek dünya ile etkileşim
            node.physicsBody?.categoryBitMask = 2 // AR obje kategorisi
            node.physicsBody?.collisionBitMask = 1 | 2 // Hem gerçek dünya (1) hem de diğer AR objelerle (2) çarpışabilir
            
            // Rastgele dönüş hareketi
            node.physicsBody?.angularVelocity = SCNVector4(
                Float.random(in: -0.5...0.5),
                Float.random(in: -0.5...0.5),
                Float.random(in: -0.5...0.5),
                Float.random(in: 0...2)
            )
            
        case "cylinder":
            geometry = SCNCylinder(radius: 0.05, height: 0.1)
            node = SCNNode(geometry: geometry)
            
            // Materyal oluştur - gövde için
            let cylinderMaterial = SCNMaterial()
            cylinderMaterial.diffuse.contents = UIColor(
                red: CGFloat(colorArray[0]) / 255.0,
                green: CGFloat(colorArray[1]) / 255.0,
                blue: CGFloat(colorArray[2]) / 255.0,
                alpha: colorArray.count > 3 ? CGFloat(colorArray[3]) / 255.0 : 1.0
            )
            cylinderMaterial.specular.contents = UIColor.white
            cylinderMaterial.shininess = 0.4
            
            // Üst ve alt kapaklar için materyal
            let capMaterial = SCNMaterial()
            capMaterial.diffuse.contents = cylinderMaterial.diffuse.contents
            capMaterial.specular.contents = UIColor.white
            capMaterial.shininess = 0.5
            capMaterial.roughness.contents = NSNumber(value: 0.7) // Kapaklar daha pürüzlü
            
            // Silindirin yan yüzeyi ve kapakları için materyal ayarla
            node.geometry?.materials = [cylinderMaterial, capMaterial, capMaterial]
            
            // Fizik özelliklerini ayarla - gerçek dünya ile etkileşim için
            node.physicsBody = SCNPhysicsBody(
                type: .dynamic,
                shape: SCNPhysicsShape(
                    geometry: geometry,
                    options: [SCNPhysicsShape.Option.collisionMargin: 0.01]
                )
            )
            
            node.physicsBody?.mass = 1.5 // Küreden biraz daha ağır
            node.physicsBody?.restitution = 0.5 // Orta zıplama katsayısı
            node.physicsBody?.friction = 0.6 // Orta sürtünme
            node.physicsBody?.rollingFriction = 0.3 // Orta seviye yuvarlanma direnci
            
            // Çarpışma maskeleri - gerçek dünya ile etkileşim
            node.physicsBody?.categoryBitMask = 2 // AR obje kategorisi
            node.physicsBody?.collisionBitMask = 1 | 2 // Hem gerçek dünya (1) hem de diğer AR objelerle (2) çarpışabilir
            
            // Rastgele dönüş hareketi - silindirler için daha fazla yuvarlanma
            node.physicsBody?.angularVelocity = SCNVector4(
                Float.random(in: -1...1),
                Float.random(in: -0.2...0.2), // Y ekseni etrafında daha az dönme
                Float.random(in: -1...1),
                Float.random(in: 0...3)
            )
            
        case "coin":
            // Madeni para - ince yassı bir silindir
            geometry = SCNCylinder(radius: 0.03, height: 0.003) // Daha ince
            node = SCNNode(geometry: geometry)
            
            // Paralara özgü metalik görünüm
            let coinMaterial = SCNMaterial()
            coinMaterial.diffuse.contents = UIColor(
                red: 0.85, // Altın rengi
                green: 0.7,
                blue: 0.3,
                alpha: 1.0
            )
            coinMaterial.specular.contents = UIColor.white
            coinMaterial.shininess = 0.9
            coinMaterial.metalness.contents = NSNumber(value: 0.8)
            
            let edgeMaterial = SCNMaterial()
            edgeMaterial.diffuse.contents = UIColor(
                red: 0.8,
                green: 0.65,
                blue: 0.25,
                alpha: 1.0
            )
            edgeMaterial.specular.contents = UIColor.white
            edgeMaterial.shininess = 0.9
            edgeMaterial.metalness.contents = NSNumber(value: 0.8)
            
            node.geometry?.materials = [edgeMaterial, coinMaterial, coinMaterial]
            
            // ROTATE THE COIN TO LIE FLAT (90 degrees around X-axis)
            node.eulerAngles.x = .pi / 2
            
            // İyileştirilmiş fizik özellikleri - daha kararlı coin için
            let coinPhysicsShape = SCNPhysicsShape(
                geometry: geometry,
                options: [
                    SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.convexHull,
                    SCNPhysicsShape.Option.collisionMargin: 0.001 // Daha hassas çarpışma
                ]
            )
            
            node.physicsBody = SCNPhysicsBody(
                type: .dynamic,
                shape: coinPhysicsShape
            )
            
            node.physicsBody?.mass = 0.2 // Daha hafif
            node.physicsBody?.restitution = 0.1 // Çok az zıplama - daha hızlı yerleşmesi için
            node.physicsBody?.friction = 0.8 // Çok fazla sürtünme - sabit durması için
            node.physicsBody?.rollingFriction = 0.8 // Çok fazla yuvarlanma direnci
            
            // Denge ve kararlılık için
            node.physicsBody?.damping = 0.7 // Yüksek sönümleme
            node.physicsBody?.angularDamping = 0.9 // Çok yüksek açısal sönümleme
            
            // Çarpışma maskeleri - gerçek dünya ile etkileşim
            node.physicsBody?.categoryBitMask = 2 // AR obje kategorisi
            node.physicsBody?.collisionBitMask = 1 | 2 // Hem gerçek dünya (1) hem de diğer AR objelerle (2) çarpışabilir
            
            // Coin için daha hafif başlangıç hareketi
            node.physicsBody?.angularVelocity = SCNVector4(
                Float.random(in: -0.1...0.1), // Çok az rastgele dönüş
                Float.random(in: -0.1...0.1),
                Float.random(in: -0.1...0.1),
                Float.random(in: 0...0.5)
            )
            
        default:
            result(false)
            return
        }
        
        // Pozisyonu ayarla
        node.position = objectPosition
        
        // Benzersiz isim ata ve kaydı tut
        node.name = id
        physicsObjects[id] = node
        
        // Rendering sırasını ve oklüzyon için derinlik testlerini ayarla
        node.renderingOrder = 100 // Gerçek dünya nesnelerinden sonra render et (oklüzyon için)
        
        // Derinlik testi ayarları
        node.castsShadow = true // Gölge oluştur
        node.categoryBitMask = 2 // Fizik kategorisiyle aynı
        
        // Daha iyi oklüzyon için her objenin malzemelerini ayarla
        for material in node.geometry?.materials ?? [] {
            // Objelerin derinlik tamponu ile doğru etkileşimi
            material.readsFromDepthBuffer = true
            material.writesToDepthBuffer = true
            
            // Işık etkileşimi
            if material.lightingModel != .physicallyBased {
                material.lightingModel = .blinn
            }
            
            // Daha net oklüzyon sınırları
            material.transparencyMode = .default
        }
        
        // Sahneye ekle
        arView.scene.rootNode.addChildNode(node)
        
        result(true)
    }
    
    private func removePhysicsObject(id: String, result: @escaping FlutterResult) {
        if let node = physicsObjects[id] {
            node.removeFromParentNode()
            physicsObjects.removeValue(forKey: id)
            result(true)
        } else {
            result(false)
        }
    }
    
    private func clearAllObjects() {
        for (_, node) in physicsObjects {
            node.removeFromParentNode()
        }
        physicsObjects.removeAll()
    }
    
    private func setPhysicsParameters(args: [String: Any], result: @escaping FlutterResult) {
        if let gravity = args["gravity"] as? Double {
            physicsScene.gravity = SCNVector3(0, Float(gravity), 0)
        }
        
        if let friction = args["friction"] as? Double {
            defaultFriction = CGFloat(friction)
        }
        
        if let restitution = args["restitution"] as? Double {
            defaultRestitution = CGFloat(restitution)
        }
        
        result(true)
    }
    
    // Oklüzyon kalitesi kontrolü - AR objelerinin gerçek nesnelerin arkasına geçme kalitesini ayarlar
    private func toggleOcclusionQuality(isHighQuality: Bool) {
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
            
            print("ARPhysicsView: High quality occlusion enabled")
        } else {
            // Performans modu - daha az kesin oklüzyon ama daha iyi performans
            // Sadece rootNode ve çocuklarına renderingOrder uygula
            arView.scene.rootNode.renderingOrder = 0
            
            // Tüm nodlar için normal render sırası
            arView.scene.rootNode.enumerateChildNodes { (node, _) in
                node.renderingOrder = 0
            }
            
            print("ARPhysicsView: Normal quality occlusion (better performance)")
        }
        
        // Oklüzyon Hata Ayıklama: Sorunları belirlemek için geçici olarak düzlemleri görünür yap
        let showDebugVisuals = false // Sadece geliştirme için true yapın
        if showDebugVisuals {
            arView.debugOptions = [.showPhysicsShapes]
        } else {
            arView.debugOptions = []
        }
    }
}

/// Flutter factory to create AR Physics Views
class ARPhysicsViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return ARPhysicsView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
} 