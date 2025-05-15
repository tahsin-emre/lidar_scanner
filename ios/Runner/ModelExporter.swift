import Foundation
import ARKit
import SceneKit

/// 3D modelleri dışa aktarma işlemlerini yöneten sınıf
class ModelExporter {
    
    /// Taranmış modeli belirtilen formatta dışa aktarır
    /// - Parameters:
    ///   - meshAnchors: Dışa aktarılacak mesh çapaları
    ///   - format: Dışa aktarma formatı (şu an sadece "obj" destekleniyor)
    ///   - fileName: Kaydedilecek dosya adı
    ///   - quality: Dışa aktarma kalitesi
    ///   - isTemporary: Dosyanın geçici olup olmadığı (varsayılan: false)
    /// - Returns: Kaydedilen dosyanın tam yolunu döndürür, başarısız olursa boş string döner
    func exportModel(meshAnchors: [ARMeshAnchor], format: String, fileName: String, quality: String, isTemporary: Bool = false) -> String {
        print("ModelExporter: exportModel called with format: \(format), filename: \(fileName), isTemporary: \(isTemporary)")

        guard format.lowercased() == "obj" else {
            print("Error: Currently only OBJ format is supported for export.")
            return ""
        }

        guard !meshAnchors.isEmpty else {
            print("Error: No mesh anchors found to export.")
            return ""
        }

        var objContent = "# Point Cloud exported from LiDAR Scanner App\n"
        var vertexOffset: Int = 0
        var normalOffset: Int = 0

        // Check if we should export in high quality mode
        let isHighQuality = quality == "highQuality"
        
        // Process each mesh anchor
        for anchor in meshAnchors {
            let geometry = anchor.geometry
            let vertices = geometry.vertices

            // Add vertices as points
            for i in 0..<vertices.count {
                let vertex = geometry.vertex(at: UInt32(i))
                // Apply the anchor's transform to get world coordinates
                let worldVertex = anchor.transform * simd_float4(vertex, 1)
                objContent += "v \(worldVertex.x) \(worldVertex.y) \(worldVertex.z)\n"
            }

            // Add normals
            for i in 0..<geometry.normals.count {
                let normal = geometry.normal(at: UInt32(i))
                let worldNormal = simd_normalize(simd_make_float3(anchor.transform * simd_float4(normal, 0)))
                objContent += "vn \(worldNormal.x) \(worldNormal.y) \(worldNormal.z)\n"
            }

            // Add faces (assuming triangles)
            if geometry.faces.primitiveType == .triangle {
                for i in 0..<geometry.faces.count {
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
            }

            // Update offsets for the next anchor's indices
            vertexOffset += vertices.count
            normalOffset += geometry.normals.count
        }

        return writeObjFile(content: objContent, fileName: fileName, isTemporary: isTemporary)
    }
    
    /// OBJ dosyasını diske yazar
    /// - Parameters:
    ///   - content: Dosya içeriği
    ///   - fileName: Dosya adı
    ///   - isTemporary: Dosyanın geçici olup olmadığı (varsayılan: false)
    /// - Returns: Kaydedilen dosyanın tam yolunu döndürür, başarısız olursa boş string döner
    private func writeObjFile(content: String, fileName: String, isTemporary: Bool = false) -> String {
        // Dosya adını hazırla
        let finalFileName = fileName.hasSuffix(".obj") ? fileName : fileName + ".obj"
        
        // Dosya konumu belirle (geçici veya kalıcı)
        let fileURL: URL
        let directoryType: String
        
        if isTemporary {
            let tempDirURL = FileManager.default.temporaryDirectory
            fileURL = tempDirURL.appendingPathComponent(finalFileName)
            directoryType = "temporary"
            
            // Mevcut geçici dosyayı temizle
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    print("Removed existing temporary file at: \(fileURL.path)")
                } catch {
                    print("Warning: Could not remove existing temporary file: \(error)")
                }
            }
        } else {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            fileURL = documentsPath.appendingPathComponent(finalFileName)
            directoryType = "documents"
        }
        
        let filePathString = fileURL.path
        print("Attempting to export OBJ to \(directoryType) directory: \(filePathString)")

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Successfully exported OBJ file to \(directoryType) directory.")
            return filePathString
        } catch {
            print("Error writing OBJ file: \(error)")
            return ""
        }
    }
    
    /// Tüm geçici OBJ dosyalarını temizler
    func cleanupTemporaryFiles() {
        let tempDirURL = FileManager.default.temporaryDirectory
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: tempDirURL, 
                                                                    includingPropertiesForKeys: nil)
            
            // Sadece .obj uzantılı ve temp_physics_scan_ ön ekli dosyaları sil
            let objFiles = fileURLs.filter { 
                $0.pathExtension == "obj" && $0.lastPathComponent.hasPrefix("temp_physics_scan_")
            }
            
            if objFiles.isEmpty {
                print("No temporary OBJ files to clean up")
                return
            }
            
            print("Cleaning up \(objFiles.count) temporary OBJ files")
            
            for fileURL in objFiles {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    print("Removed temporary file: \(fileURL.lastPathComponent)")
                } catch {
                    print("Error removing temporary file \(fileURL.lastPathComponent): \(error)")
                }
            }
        } catch {
            print("Error listing temporary directory contents: \(error)")
        }
    }
} 