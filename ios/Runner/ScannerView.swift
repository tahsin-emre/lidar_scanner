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

    // Update the function signature to accept a fileName
    func exportModel(format: String, fileName: String) -> String {
        print("Native iOS: exportModel called with format: \(format), filename: \(fileName)")

        guard format.lowercased() == "obj" else {
            print("Error: Currently only OBJ format is supported for export.")
            return "" // Return empty path or an error indicator
        }

        guard let frame = session.currentFrame else {
            print("Error: Cannot export model, ARFrame not available.")
            return ""
        }

        // Access mesh anchors from the current frame
        let meshAnchors = frame.anchors.compactMap { $0 as? ARMeshAnchor }

        guard !meshAnchors.isEmpty else {
            print("Error: No mesh anchors found to export.")
            return ""
        }

        var objContent = "# Exported from LiDAR Scanner App\n"
        var vertexOffset: Int = 0
        var normalOffset: Int = 0

        // Process each mesh anchor
        for anchor in meshAnchors {
            let geometry = anchor.geometry
            let vertices = geometry.vertices
            let normals = geometry.normals
            let faces = geometry.faces

            // Add vertices
            for i in 0..<vertices.count {
                let vertex = geometry.vertex(at: UInt32(i))
                // Apply the anchor's transform to get world coordinates
                let worldVertex = anchor.transform * simd_float4(vertex, 1)
                objContent += "v \(worldVertex.x) \(worldVertex.y) \(worldVertex.z)\n"
            }

            // Add normals
            for i in 0..<normals.count {
                let normal = geometry.normal(at: UInt32(i))
                // Normals are direction vectors, only rotation part of transform matters.
                // We assume the normal is in the anchor's local space and needs rotation.
                // Simplified: We might need more precise normal transformation if scale/shear is involved.
                // For simple rotation/translation, transforming the direction vector is okay.
                let worldNormal = simd_normalize(simd_make_float3(anchor.transform * simd_float4(normal, 0)))
                objContent += "vn \(worldNormal.x) \(worldNormal.y) \(worldNormal.z)\n"
            }

            // Add faces (assuming triangles)
            if faces.primitiveType == .triangle {
                for i in 0..<faces.count {
                    let faceIndices = geometry.faceIndices(at: i)
                    let v1 = Int(faceIndices[0]) + 1 + vertexOffset // OBJ is 1-based
                    let v2 = Int(faceIndices[1]) + 1 + vertexOffset
                    let v3 = Int(faceIndices[2]) + 1 + vertexOffset

                    // Assuming vertex index corresponds to normal index
                    let n1 = Int(faceIndices[0]) + 1 + normalOffset
                    let n2 = Int(faceIndices[1]) + 1 + normalOffset
                    let n3 = Int(faceIndices[2]) + 1 + normalOffset

                    objContent += "f \(v1)//\(n1) \(v2)//\(n2) \(v3)//\(n3)\n"
                }
            } else {
                 print("Warning: Skipping faces with non-triangle primitive type in anchor \(anchor.identifier).")
            }

            // Update offsets for the next anchor's indices
            vertexOffset += vertices.count
            normalOffset += normals.count
        }

        // --- File Writing ---
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        // Create a unique filename using timestamp -> Use the provided fileName instead
        // let timestamp = Int(Date().timeIntervalSince1970)
        // let fileName = "scan_\(timestamp).obj"

        // Ensure the provided filename ends with .obj
        let finalFileName = fileName.hasSuffix(".obj") ? fileName : fileName + ".obj"

        let fileURL = documentsPath.appendingPathComponent(finalFileName)
        let filePathString = fileURL.path

        print("Attempting to export OBJ to: \(filePathString)")

        do {
            try objContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Successfully exported OBJ file.")
            return filePathString // Return the actual path
        } catch {
            print("Error writing OBJ file: \(error)")
            return "" // Return empty string on error
        }
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

// Helper extension to create SCNGeometry from ARMeshGeometry
@available(iOS 13.4, *)
extension ARMeshGeometry {
    func vertex(at index: UInt32) -> SIMD3<Float> {
        assert(vertices.format == MTLVertexFormat.float3, "Expected three floats (vertexExecutionOrder.format) for vertices.")
        let vertexPointer = vertices.buffer.contents().advanced(by: vertices.offset + (vertices.stride * Int(index)))
        return vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
    }

     func normal(at index: UInt32) -> SIMD3<Float> {
        assert(normals.format == MTLVertexFormat.float3, "Expected three floats (vertexExecutionOrder.format) for normals.")
        let normalPointer = normals.buffer.contents().advanced(by: normals.offset + (normals.stride * Int(index)))
        return normalPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
    }

    func faceIndices(at index: Int) -> SIMD3<UInt32> {
        assert(faces.bytesPerIndex == MemoryLayout<UInt32>.size, "Expected UInt32 (vertexExecutionOrder.bytesPerIndex) for indices.")
        let faceIndicesPointer = faces.buffer.contents().advanced(by: (faces.indexCountPerPrimitive * faces.bytesPerIndex * index))
        return faceIndicesPointer.assumingMemoryBound(to: SIMD3<UInt32>.self).pointee
    }
} 