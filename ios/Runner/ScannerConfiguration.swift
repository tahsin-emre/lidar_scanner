import Foundation
import ARKit
import SceneKit

/// Tarayıcı yapılandırmasını yöneten sınıf
class ScannerConfiguration {
    
    /// Varsayılan AR yapılandırmasını ayarlar
    /// - Parameter scannerView: Yapılandırılacak ScannerView
    func setupDefaultConfiguration(for scannerView: ScannerView) {
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            scannerView.configuration.sceneReconstruction = .mesh
        } else {
            print("Device does not support LiDAR mesh reconstruction.")
            return
        }
        
        scannerView.configuration.planeDetection = [.horizontal, .vertical]
        
        // Add lighting to the scene
        setupLighting(for: scannerView)
    }
    
    /// Sahne için ışıklandırmayı ayarlar
    /// - Parameter scannerView: Işıklandırılacak ScannerView
    func setupLighting(for scannerView: ScannerView) {
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.darkGray
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scannerView.arView.scene.rootNode.addChildNode(ambientLightNode)
        
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = UIColor.white
        directionalLight.intensity = 1000
        let directionalLightNode = SCNNode()
        directionalLightNode.light = directionalLight
        directionalLightNode.position = SCNVector3(x: 0, y: 10, z: 1)
        scannerView.arView.scene.rootNode.addChildNode(directionalLightNode)
    }
    
    /// Tarama için gerekli yapılandırmaları yapar
    /// - Parameter scannerView: Yapılandırılacak ScannerView
    func configureScanning(for scannerView: ScannerView) {
        // Reset configuration
        scannerView.configuration = ARWorldTrackingConfiguration()
        
        // Enable mesh reconstruction for all scan types
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            scannerView.configuration.sceneReconstruction = .mesh
        }
        
        // Set environment texturing to automatic for all qualities
        scannerView.configuration.environmentTexturing = .automatic
        
        // Configure quality settings based on scan type
        switch scannerView.currentscanQuality {
        case "highQuality":
            // High quality scan settings
            scannerView.arView.antialiasingMode = .multisampling4X
            scannerView.arView.debugOptions = []
        case "lowQuality":
            // Low quality scan settings
            scannerView.arView.antialiasingMode = .none
            scannerView.arView.debugOptions = []
        default:
            // Default to high quality
            scannerView.arView.antialiasingMode = .multisampling4X
            scannerView.arView.debugOptions = []
        }
        
        // Enable automatic lighting updates
        scannerView.arView.automaticallyUpdatesLighting = true
        
        // Enable plane detection
        scannerView.configuration.planeDetection = [.horizontal, .vertical]
        
        // Oda tarama modunu yapılandır
        setupRoomScanMode(for: scannerView)
    }
    
    /// Oda tarama modunu yapılandırır
    /// - Parameter scannerView: Yapılandırılacak ScannerView
    func setupRoomScanMode(for scannerView: ScannerView) {
        print("Configured for room scan mode")
        
        // Oda tarama yapılandırması
        // Maksimum mesafe ayarı (metre)
        let maxDistance: Float = 10.0
        
        // Ek oda tarama ayarları burada yapılabilir
        let roomScanConfig: [String: Any] = [
            "focusMode": false,
            "objectIsolation": false,
            "backgroundRemoval": false,
            "maxDistance": maxDistance,
            "autoCenter": false,
        ]
        
        // Gerekirse yapılandırmayı güncelleyebilirsiniz
        if var config = scannerView.scanConfiguration as? [String: Any] {
            for (key, value) in roomScanConfig {
                config[key] = value
            }
            scannerView.scanConfiguration = config
        }
    }
} 