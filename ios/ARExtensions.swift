import Foundation
import ARKit
import SceneKit

// MARK: - Yardımcı Uzantılar

/// ARMeshGeometry'den SCNGeometry oluşturmak için yardımcı uzantı
@available(iOS 13.4, *)
extension SCNGeometry {
    /// AR Mesh Geometrisini SceneKit geometrisine dönüştürür
    /// - Parameter arGeometry: Dönüştürülecek AR Mesh geometrisi
    convenience init(arGeometry: ARMeshGeometry) {
        let verticesSource = SCNGeometrySource(
            buffer: arGeometry.vertices.buffer,
            vertexFormat: arGeometry.vertices.format,
            semantic: .vertex,
            vertexCount: arGeometry.vertices.count,
            dataOffset: arGeometry.vertices.offset,
            dataStride: arGeometry.vertices.stride
        )
        
        let normalsSource = SCNGeometrySource(
            buffer: arGeometry.normals.buffer,
            vertexFormat: arGeometry.normals.format,
            semantic: .normal,
            vertexCount: arGeometry.normals.count,
            dataOffset: arGeometry.normals.offset,
            dataStride: arGeometry.normals.stride
        )
        
        let facesElement = SCNGeometryElement(
            buffer: arGeometry.faces.buffer,
            primitiveType: SCNGeometryPrimitiveType(arPrimitiveType: arGeometry.faces.primitiveType)!,
            primitiveCount: arGeometry.faces.count,
            bytesPerIndex: arGeometry.faces.bytesPerIndex
        )

        self.init(sources: [verticesSource, normalsSource], elements: [facesElement])
    }
}

/// ARKit ilkel tiplerini SceneKit ilkel tiplerine eşlemek için yardımcı uzantı
@available(iOS 13.4, *)
extension SCNGeometryPrimitiveType {
    /// ARKit geometri ilkel tipini SceneKit ilkel tipine dönüştürür
    /// - Parameter arPrimitiveType: ARKit ilkel tipi
    /// - Returns: SceneKit ilkel tipi veya nil
    init?(arPrimitiveType: ARGeometryPrimitiveType) {
        switch arPrimitiveType {
        case .line:
            self = .line
        case .triangle:
            self = .triangles
        default:
            return nil // Nokta tipleri eleman olarak doğrudan desteklenmiyor
        }
    }
}

/// ARMeshGeometry'den vertex ve normal bilgilerini almak için yardımcı uzantı
@available(iOS 13.4, *)
extension ARMeshGeometry {
    /// Belirtilen indeksteki vertex'i döndürür
    /// - Parameter index: Vertex indeksi
    /// - Returns: 3D vertex koordinatları
    func vertex(at index: UInt32) -> SIMD3<Float> {
        assert(vertices.format == MTLVertexFormat.float3, "Vertices için üç float (vertexExecutionOrder.format) bekleniyor.")
        let vertexPointer = vertices.buffer.contents().advanced(by: vertices.offset + (vertices.stride * Int(index)))
        return vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
    }

    /// Belirtilen indeksteki normal vektörünü döndürür
    /// - Parameter index: Normal indeksi
    /// - Returns: 3D normal vektörü
    func normal(at index: UInt32) -> SIMD3<Float> {
        assert(normals.format == MTLVertexFormat.float3, "Normals için üç float (vertexExecutionOrder.format) bekleniyor.")
        let normalPointer = normals.buffer.contents().advanced(by: normals.offset + (normals.stride * Int(index)))
        return normalPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
    }

    /// Belirtilen indeksteki yüz indekslerini döndürür
    /// - Parameter index: Yüz indeksi
    /// - Returns: Üçgen yüzü oluşturan üç vertex indeksi
    func faceIndices(at index: Int) -> SIMD3<UInt32> {
        assert(faces.bytesPerIndex == MemoryLayout<UInt32>.size, "İndeks için UInt32 (vertexExecutionOrder.bytesPerIndex) bekleniyor.")
        let faceIndicesPointer = faces.buffer.contents().advanced(by: (faces.indexCountPerPrimitive * faces.bytesPerIndex * index))
        return faceIndicesPointer.assumingMemoryBound(to: SIMD3<UInt32>.self).pointee
    }
} 