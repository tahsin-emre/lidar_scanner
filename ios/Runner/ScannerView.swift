import Flutter
import UIKit
import ARKit
import SceneKit
// ARExtensions.swift'deki yardımcı uzantılarımızı kullanabilmek için bunun içe aktarıldığından emin olun
// Eğer bu modülde değilse, doğrudan dosya içeriğinin derleyici tarafından erişilmesini sağlayacaktır

/// LiDAR tarama işlemlerini yöneten ve Flutter platformu ile iletişim kuran ana sınıf
class ScannerView: NSObject, FlutterPlatformView, ARSCNViewDelegate, ARSessionDelegate {
    // MARK: - Properties
    var arView: ARSCNView!
    let session = ARSession()
    var configuration = ARWorldTrackingConfiguration()
    
    private var isScanning = false
    var currentscanQuality: String = "high"
    var scanConfiguration: [String: Any] = [:]
    private var lastUpdateTime: TimeInterval = 0
    
    private let meshProcessor: MeshProcessor
    private let modelExporter: ModelExporter
    private let scannerConfiguration: ScannerConfiguration
    
    // MARK: - Initialization
    
    /// ScannerView'ı başlatır ve ARSCNView'ı yapılandırır
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        // Önce yardımcı bileşenleri oluştur
        self.meshProcessor = MeshProcessor()
        self.modelExporter = ModelExporter()
        self.scannerConfiguration = ScannerConfiguration()
        
        super.init()
        
        // AR View'ı oluştur ve yapılandır
        arView = ARSCNView(frame: frame)
        arView.session = session
        arView.delegate = self
        session.delegate = self
        
        // Varsayılan yapılandırmayı uygula
        scannerConfiguration.setupDefaultConfiguration(for: self)
    }
    
    /// Flutter platformu tarafından kullanılan view'ı döndürür
    func view() -> UIView {
        return arView
    }
    
    // MARK: - Public Control Methods
    
    /// LiDAR taramasını başlatır
    /// - Parameters:
    ///   - scanQuality: Tarama kalitesi ("highQuality", "lowQuality", "medium")
    ///   - configuration: Tarama yapılandırma ayarları
    func startScanning(scanQuality: String, scanType: String, configuration: [String: Any]) {
        guard ARWorldTrackingConfiguration.isSupported else {
            print("ARWorldTracking is not supported on this device.")
            return
        }
        
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) else {
            print("Scene reconstruction is not supported on this device.")
            return
        }
        
        self.currentscanQuality = scanQuality
        self.scanConfiguration = configuration
        
        // Taramayı yapılandır
        scannerConfiguration.configureScanning(for: self)
        
        print("Native iOS: Starting AR session with quality: \(scanQuality)")
        isScanning = true
        session.run(self.configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    /// Devam eden taramayı durdurur
    func stopScanning() {
        print("Native iOS: Stopping AR session")
        isScanning = false
        session.pause()
    }
    
    /// Tarama ilerlemesini döndürür
    /// - Returns: Tarama ilerleme bilgilerini içeren sözlük
    func getScanProgress() -> [String: Any] {
        print("Native iOS: getScanProgress called")
        let progressData: [String: Any] = [
            "progress": isScanning ? 0.5 : 0.0, // Placeholder
            "isComplete": !isScanning,          // Placeholder
            "missingAreas": []                  // Placeholder
        ]
        return progressData
    }

    /// Taranmış modeli belirtilen formatta dışa aktarır
    /// - Parameters:
    ///   - format: Dışa aktarma formatı (şu an sadece "obj" destekleniyor)
    ///   - fileName: Kaydedilecek dosya adı
    /// - Returns: Kaydedilen dosyanın tam yolunu döndürür, başarısız olursa boş string döner
    func exportModel(format: String, fileName: String) -> String {
        guard let frame = session.currentFrame else {
            print("Error: Cannot export model, ARFrame not available.")
            return ""
        }
        
        let meshAnchors = frame.anchors.compactMap { $0 as? ARMeshAnchor }
        return modelExporter.exportModel(
            meshAnchors: meshAnchors,
            format: format,
            fileName: fileName,
            quality: currentscanQuality
        )
    }
    
    // MARK: - ARSessionDelegate
    
    /// AR session çerçeve güncellemesi
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard isScanning else { return }
        
        // Güncelleme aralığını kontrol et
        let currentTime = CACurrentMediaTime()
        if let updateInterval = scanConfiguration["updateInterval"] as? Double {
            if currentTime - lastUpdateTime < updateInterval {
                return
            }
            lastUpdateTime = currentTime
        }
        
        // Mesh işleme
        let meshAnchors = frame.anchors.compactMap { $0 as? ARMeshAnchor }
        meshProcessor.processMeshes(meshAnchors, withQuality: currentscanQuality)
    }
    
    /// AR session hatası
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("ARSession failed: \(error.localizedDescription)")
        isScanning = false
    }

    /// AR session kesintisi
    func sessionWasInterrupted(_ session: ARSession) {
        print("ARSession interrupted")
        isScanning = false
    }

    /// AR session kesinti sonu
    func sessionInterruptionEnded(_ session: ARSession) {
        print("ARSession interruption ended")
    }

    // MARK: - ARSCNViewDelegate

    /// Bu metod, ARKit tarafından bulunan mesh çapalarını görselleştirmeye yardımcı olur
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let meshAnchor = anchor as? ARMeshAnchor else {
            return nil
        }
        
        return meshProcessor.createNodeForMeshAnchor(meshAnchor, withQuality: currentscanQuality)
    }

    /// Bu metod, ARKit mesh'i yenilendiğinde geometriyi günceller
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let meshAnchor = anchor as? ARMeshAnchor else {
            return
        }
        
        meshProcessor.updateNodeForMeshAnchor(node, meshAnchor: meshAnchor, withQuality: currentscanQuality)
    }
} 