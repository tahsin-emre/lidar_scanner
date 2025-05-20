import SceneKit
import ARKit
import UIKit

/// AR Fiziksel Objelerin Yönetimi
class ARPhysicsObjectManager {
    // MARK: - Properties
    private var arView: ARSCNView
    private var physicsObjects = [String: SCNNode]()
    
    private var defaultFriction: CGFloat = 0.5
    private var defaultRestitution: CGFloat = 0.4
    
    // MARK: - Initialization
    init(arView: ARSCNView) {
        self.arView = arView
    }
    
    // MARK: - Public Methods
    
    /// Tüm fiziksel objeleri temizler
    func clearAllObjects() {
        for (_, node) in physicsObjects {
            node.removeFromParentNode()
        }
        physicsObjects.removeAll()
    }
    
    /// Belirli bir ID'ye sahip fiziksel objeyi kaldırır
    func removePhysicsObject(id: String) -> Bool {
        if let node = physicsObjects[id] {
            node.removeFromParentNode()
            physicsObjects.removeValue(forKey: id)
            return true
        } else {
            return false
        }
    }
    
    /// Fizik parametrelerini ayarlar
    func setPhysicsParameters(gravity: Double? = nil, friction: Double? = nil, restitution: Double? = nil) {
        if let gravity = gravity {
            arView.scene.physicsWorld.gravity = SCNVector3(0, Float(gravity), 0)
        }
        
        if let friction = friction {
            defaultFriction = CGFloat(friction)
        }
        
        if let restitution = restitution {
            defaultRestitution = CGFloat(restitution)
        }
    }
    
    /// Yeni bir fiziksel obje ekler
    func addPhysicsObject(objectData: [String: Any]) -> Bool {
        guard let id = objectData["id"] as? String,
              let type = objectData["type"] as? String,
              let position = objectData["position"] as? [Double],
              let colorArray = objectData["color"] as? [Int] else {
            print("ARPhysicsObjectManager: Missing required parameters for adding physics object")
            return false
        }
        
        guard position.count >= 3 else {
            print("ARPhysicsObjectManager: Position array must have at least 3 elements")
            return false
        }
        
        print("ARPhysicsObjectManager: Adding \(type) at position \(position)")
        
        // Convert position to SCNVector3
        let objectPosition = SCNVector3(
            Float(position[0]),
            Float(position[1]),
            Float(position[2])
        )
        
        // Obje oluşturma fonksiyonunu çağır
        guard let node = createObject(ofType: type, withColor: colorArray) else {
            return false
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
        
        return true
    }
    
    // MARK: - Private Methods
    
    /// İstenen tipte obje oluşturur
    private func createObject(ofType type: String, withColor colorArray: [Int]) -> SCNNode? {
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
            return nil
        }
        
        return node
    }
} 