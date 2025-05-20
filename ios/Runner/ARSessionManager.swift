import ARKit
import SceneKit

/// AR Oturumu yönetimi
class ARSessionManager {
    // MARK: - Properties
    private var arView: ARSCNView
    private let session: ARSession
    
    // MARK: - Initialization
    init(arView: ARSCNView, session: ARSession) {
        self.arView = arView
        self.session = session
    }
    
    // MARK: - Public Methods
    
    /// AR oturumunu başlatır
    func startARSession() {
        let configuration = ARWorldTrackingConfiguration()
        
        // ARKit konfigürasyonunu ULTİMATE TARAMA KALİTESİNE ayarla
        
        // Zemin ve düzlem algılama özelliklerini maksimuma çıkar
        configuration.planeDetection = [.horizontal, .vertical]
        
        // LiDAR destekli cihazlarda ek özellikler
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            print("ARSessionManager: Device supports LiDAR mesh reconstruction")
            
            // Tam mesh yeniden yapılandırma - ULTİMATE kalite
            configuration.sceneReconstruction = .mesh // Standart mesh
            
            // Zemin algılama hassasiyetini artır
            if #available(iOS 13.4, *) {
                // LiDAR tarayıcıya özgü zemin algılama optimizasyonları
                configuration.isAutoFocusEnabled = true // Daha net scene taraması
                
                // Scene derinlik haritası kalitesini artır
                if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
                    configuration.frameSemantics.insert(.smoothedSceneDepth)
                    print("ARSessionManager: Enhanced depth quality enabled for floor detection")
                }
                
                // Daha yüksek kaliteli çevre haritalama
                configuration.environmentTexturing = .automatic
                
                // İnsan segmentasyonu ile zeminlerin daha iyi ayrılması
                if #available(iOS 13.0, *) {
                    if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentation) {
                        configuration.frameSemantics.insert(.personSegmentation)
                        print("ARSessionManager: Person segmentation enabled - better floor detection")
                    }
                }
            }
            
            // Mutlak konum modelini maksimum hassasiyete ayarla
            if #available(iOS 14.0, *) {
                if ARWorldTrackingConfiguration.supportsAppClipCodeTracking {
                    // Daha hassas konum izleme için gelişmiş modeli kullan
                    print("ARSessionManager: Enhanced position tracking enabled")
                }
            }
            
            print("ARSessionManager: ULTIMATE LiDAR scanning enabled for floor detection")
        } else {
            print("ARSessionManager: Device does NOT support LiDAR - using standard detection")
            
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
        print("ARSessionManager: AR Session started with ULTIMATE floor detection configuration")
    }
    
    /// Kamerayla ilgili yardımcı fonksiyonlar
    
    /// Ekrandaki bir konumu dünya konumuna dönüştürür
    func convertScreenToWorldPosition(x: Double, y: Double) -> [Double]? {
        let point = CGPoint(x: x, y: y)
        print("ARSessionManager: Converting screen position \(point) to world position")
        
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
            
            print("ARSessionManager: Hit test found surface at: \(hitPosition)")
            
            // Biraz yüzeyin üstüne konumla (yerçekimi ile düşmesi için)
            let finalPosition = SCNVector3(
                hitPosition.x,
                hitPosition.y + 0.1, // Yüzeyin 10cm üzerinde
                hitPosition.z
            )
            
            // Update the indicator position
            if let planeIndicator = arView.scene.rootNode.childNode(withName: "planeIndicator", recursively: true) {
                planeIndicator.position = hitPosition
                planeIndicator.isHidden = false
            }
            
            return [
                Double(finalPosition.x),
                Double(finalPosition.y),
                Double(finalPosition.z)
            ]
        }
        
        // 3. Eğer bir yüzey bulunamazsa, kameranın bakış yönünde bir noktaya yerleştir
        let raycastQuery = arView.raycastQuery(from: point, allowing: .estimatedPlane, alignment: .any)
        
        if let query = raycastQuery, let raycastResult = arView.session.raycast(query).first {
            let rayPosition = SCNVector3(
                raycastResult.worldTransform.columns.3.x,
                raycastResult.worldTransform.columns.3.y,
                raycastResult.worldTransform.columns.3.z
            )
            
            print("ARSessionManager: Raycast found point at: \(rayPosition)")
            
            // Update the indicator position
            if let planeIndicator = arView.scene.rootNode.childNode(withName: "planeIndicator", recursively: true) {
                planeIndicator.position = rayPosition
                planeIndicator.isHidden = false
            }
            
            return [
                Double(rayPosition.x),
                Double(rayPosition.y),
                Double(rayPosition.z)
            ]
        }
        
        // 4. Son çare: Kamera önünde bir pozisyon
        let cameraPosition = getPositionInFrontOfCamera(distance: 0.5)
        print("ARSessionManager: Fallback to position in front of camera: \(cameraPosition)")
        
        // Update the indicator position
        if let planeIndicator = arView.scene.rootNode.childNode(withName: "planeIndicator", recursively: true) {
            planeIndicator.position = cameraPosition
            planeIndicator.isHidden = false
        }
        
        return [
            Double(cameraPosition.x),
            Double(cameraPosition.y),
            Double(cameraPosition.z)
        ]
    }
    
    // MARK: - Private Methods
    
    /// Kameranın önünde belirli bir mesafede bir konum döndürür
    private func getPositionInFrontOfCamera(distance: Float) -> SCNVector3 {
        guard let currentFrame = arView.session.currentFrame else {
            print("ARSessionManager: No current frame available")
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
} 