import Flutter
import UIKit
import ARKit
import SceneKit

/// Tarama ile eşzamanlı olarak AR objeleri yerleştirmek için görünüm
class ARPhysicsView: NSObject, FlutterPlatformView, ARSCNViewDelegate {
    // MARK: - Properties
    private var arView: ARSCNView!
    private let session = ARSession()
    
    private var physicsObjects = [String: SCNNode]()
    private var lastFrameTime: TimeInterval = 0
    private var frameCount = 0
    private var currentFps: Double = 0
    
    // Manager sınıfları
    private var objectManager: ARPhysicsObjectManager!
    private var collisionManager: ARCollisionManager!
    private var sessionManager: ARSessionManager!
    private var methodChannelHandler: ARMethodChannelHandler!
    
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
        
        // Manager sınıflarını oluştur
        objectManager = ARPhysicsObjectManager(arView: arView)
        collisionManager = ARCollisionManager(arView: arView)
        sessionManager = ARSessionManager(arView: arView, session: session)
        methodChannelHandler = ARMethodChannelHandler(arPhysicsView: self)
        
        // Metodları Flutter'a kaydet
        methodChannelHandler.registerMethodChannel(messenger: messenger, viewId: viewId)
        
        // AR oturumunu başlat
        sessionManager.startARSession()
        
        // Düzlem algılama göstergesi ekle
        collisionManager.addPlaneIndicator()
        
        // Yüksek kaliteli oklüzyon modunu aktif et
        collisionManager.toggleOcclusionQuality(isHighQuality: true)
    }
    
    // MARK: - Public methods
    func view() -> UIView {
        print("ARPhysicsView: Returning ARView instance")
        return arView
    }
    
    // MARK: - ARSCNViewDelegate Methods
    
    // Yeni bir anchor eklendiğinde
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            print("ARPhysicsView: Plane detected at \(planeAnchor.transform)")
            collisionManager.addCollisionPlane(for: planeAnchor, to: node)
        } else if #available(iOS 13.4, *), let meshAnchor = anchor as? ARMeshAnchor {
            print("ARPhysicsView: Mesh detected")
            collisionManager.addCollisionMesh(for: meshAnchor, to: node)
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
                collisionManager.addCollisionPlane(for: planeAnchor, to: node)
            }
            
        } else if #available(iOS 13.4, *), let meshAnchor = anchor as? ARMeshAnchor {
            print("ARPhysicsView: Mesh updated: \(meshAnchor.identifier.uuidString)")
            
            // Mevcut çakışma meshini kaldır
            node.childNodes.forEach { $0.removeFromParentNode() }
            
            // Yeni çakışma meshi ekle
            collisionManager.addCollisionMesh(for: meshAnchor, to: node)
            
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
    
    // MARK: - Flutter Method Channel Handlers
    
    /// Yeni bir fiziksel obje ekler
    func handleAddPhysicsObject(objectData: [String: Any], result: @escaping FlutterResult) {
        let success = objectManager.addPhysicsObject(objectData: objectData)
        result(success)
    }
    
    /// Belirli bir fiziksel objeyi kaldırır
    func handleRemovePhysicsObject(id: String, result: @escaping FlutterResult) {
        let success = objectManager.removePhysicsObject(id: id)
        result(success)
    }
    
    /// Tüm fiziksel objeleri temizler
    func handleClearAllObjects(result: @escaping FlutterResult) {
        objectManager.clearAllObjects()
        result(true)
    }
    
    /// Ekran konumunu dünya konumuna dönüştürür
    func handleScreenToWorldPosition(x: Double, y: Double, result: @escaping FlutterResult) {
        if let worldPosition = sessionManager.convertScreenToWorldPosition(x: x, y: y) {
            result(worldPosition)
        } else {
            result(FlutterError(code: "CONVERSION_FAILED", 
                              message: "Failed to convert screen position to world position", 
                              details: nil))
        }
    }
    
    /// Fizik parametrelerini ayarlar
    func handleSetPhysicsParameters(args: [String: Any], result: @escaping FlutterResult) {
        let gravity = args["gravity"] as? Double
        let friction = args["friction"] as? Double
        let restitution = args["restitution"] as? Double
        
        objectManager.setPhysicsParameters(
            gravity: gravity,
            friction: friction,
            restitution: restitution
        )
        
        result(true)
    }
    
    /// Mevcut FPS değerini döndürür
    func handleGetFps(result: @escaping FlutterResult) {
        result(currentFps)
    }
} 