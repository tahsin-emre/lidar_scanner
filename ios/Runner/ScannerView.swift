import Flutter
import UIKit
import ARKit
import SceneKit

class ScannerView: NSObject, FlutterPlatformView, ARSCNViewDelegate, ARSessionDelegate {
    var arView: ARSCNView!
    let session = ARSession()
    let configuration = ARWorldTrackingConfiguration()

    private var isScanning = false

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        super.init()
        // Create and configure ARSCNView
        arView = ARSCNView(frame: frame)
        arView.session = session
        arView.delegate = self
        session.delegate = self

        // Configure ARWorldTrackingConfiguration for LiDAR scanning
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        } else {
            print("Device does not support LiDAR mesh reconstruction.")
            // Handle the case where LiDAR is not supported, maybe show an alert
        }
        configuration.planeDetection = [.horizontal, .vertical] // Optional: detect planes

        // Add lighting to the scene (optional, but makes meshes visible)
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.darkGray
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        arView.scene.rootNode.addChildNode(ambientLightNode)

        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = UIColor.white
        directionalLight.intensity = 1000
        let directionalLightNode = SCNNode()
        directionalLightNode.light = directionalLight
        directionalLightNode.position = SCNVector3(x: 0, y: 10, z: 1)
        arView.scene.rootNode.addChildNode(directionalLightNode)
    }

    func view() -> UIView {
        return arView
    }

    // MARK: - Public Control Methods

    func startScanning() {
        guard ARWorldTrackingConfiguration.isSupported else {
            print("ARWorldTracking is not supported on this device.")
            // Optionally send an error back to Flutter
            return
        }
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) else {
             print("Scene reconstruction is not supported on this device.")
             // Optionally send an error back to Flutter
             return
         }

        print("Native iOS: Starting AR session")
        isScanning = true
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func stopScanning() {
        print("Native iOS: Stopping AR session")
        isScanning = false
        session.pause()
    }

    func getScanProgress() -> [String: Any] {
        print("Native iOS: getScanProgress called")
        // TODO: Implement actual progress calculation based on mesh coverage or time
        let progressData: [String: Any] = [
            "progress": isScanning ? 0.5 : 0.0, // Placeholder
            "isComplete": !isScanning,        // Placeholder
            "missingAreas": []                 // Placeholder - complex to calculate
        ]
        return progressData
    }

    func exportModel(format: String) -> String {
        print("Native iOS: exportModel called with format: \(format)")
        // TODO: Implement actual model export using ARMeshAnchors
        // Access mesh anchors: let meshAnchors = session.currentFrame?.anchors.compactMap { $0 as? ARMeshAnchor }
        // Convert mesh data to requested format (OBJ, USDZ etc.) - Requires significant work or libraries.

        // Placeholder implementation
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        // Construct the URL correctly
        let fileURL = documentsPath.appendingPathComponent("scan_export.\(format.lowercased())") // Keep as URL initially
        let filePathString = fileURL.path // Get the string path
        print("Placeholder export path: \(filePathString)")
        // Simulate saving a dummy file using the string path
        do {
            try "dummy content".write(toFile: filePathString, atomically: true, encoding: .utf8)
        } catch {
            print("Error writing dummy file: \(error)")
            // Handle error appropriately, maybe return an empty string or specific error indicator
            return "" // Return empty string on error
        }

        return filePathString // Return the string path
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didFailWithError error: Error) {
        print("ARSession failed: \(error.localizedDescription)")
        // Handle session errors, maybe inform Flutter
        isScanning = false
    }

    func sessionWasInterrupted(_ session: ARSession) {
        print("ARSession interrupted")
        // Handle interruptions (e.g., phone call)
        isScanning = false
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        print("ARSession interruption ended")
        // Reset tracking or resume session as appropriate
        // Consider automatically restarting scanning if it was active
        // For simplicity, we'll require the user to restart manually
    }

    // MARK: - ARSCNViewDelegate (Optional - for visualizing geometry)

    // This delegate method helps visualize the mesh anchors ARKit finds.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let meshAnchor = anchor as? ARMeshAnchor else {
            return nil
        }

        // Create a SCNGeometry from the mesh anchor's geometry.
        let geometry = SCNGeometry(arGeometry: meshAnchor.geometry)

        // Create a node to hold the geometry. Use a wireframe material for visualization.
        let node = SCNNode(geometry: geometry)
        node.geometry?.firstMaterial?.fillMode = .lines // Wireframe
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow // Wireframe color

        return node
    }

    // This delegate method updates the geometry when ARKit refines the mesh.
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let meshAnchor = anchor as? ARMeshAnchor else {
            return
        }

        // Recreate the geometry entirely on update for simplicity and robustness
        let newGeometry = SCNGeometry(arGeometry: meshAnchor.geometry)
        node.geometry = newGeometry
        // Reapply visualization settings
        node.geometry?.firstMaterial?.fillMode = .lines
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
    }
}

// Helper extension to create SCNGeometry from ARMeshGeometry
@available(iOS 13.4, *)
extension SCNGeometry {
    convenience init(arGeometry: ARMeshGeometry) {
        let verticesSource = SCNGeometrySource(buffer: arGeometry.vertices.buffer, vertexFormat: arGeometry.vertices.format, semantic: .vertex, vertexCount: arGeometry.vertices.count, dataOffset: arGeometry.vertices.offset, dataStride: arGeometry.vertices.stride)
        let normalsSource = SCNGeometrySource(buffer: arGeometry.normals.buffer, vertexFormat: arGeometry.normals.format, semantic: .normal, vertexCount: arGeometry.normals.count, dataOffset: arGeometry.normals.offset, dataStride: arGeometry.normals.stride)
        let facesElement = SCNGeometryElement(buffer: arGeometry.faces.buffer, primitiveType: SCNGeometryPrimitiveType(arPrimitiveType: arGeometry.faces.primitiveType)!, primitiveCount: arGeometry.faces.count, bytesPerIndex: arGeometry.faces.bytesPerIndex)

        self.init(sources: [verticesSource, normalsSource], elements: [facesElement])
    }
}

// Helper extension to map ARKit primitive types to SceneKit primitive types
@available(iOS 13.4, *)
extension SCNGeometryPrimitiveType {
    init?(arPrimitiveType: ARGeometryPrimitiveType) {
        switch arPrimitiveType {
        case .line: self = .line
        case .triangle: self = .triangles
        default: return nil // point types not directly supported as elements
        }
    }
} 