import Flutter
import UIKit
import ARKit

/// Flutter Method Channel entegrasyonu
class ARMethodChannelHandler {
    // MARK: - Properties
    private weak var arPhysicsView: ARPhysicsView?
    private var channel: FlutterMethodChannel?
    
    // MARK: - Initialization
    init(arPhysicsView: ARPhysicsView) {
        self.arPhysicsView = arPhysicsView
    }
    
    // MARK: - Public Methods
    
    /// Method Channel'ı kaydet
    func registerMethodChannel(messenger: FlutterBinaryMessenger?, viewId: Int64) {
        guard let messenger = messenger else { return }
        
        let channelName = "com.example.lidarScanner/arPhysics_\(viewId)"
        print("ARMethodChannelHandler: Registering method channel: \(channelName)")
        
        channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: messenger
        )
        
        channel?.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self, let arPhysicsView = self.arPhysicsView else {
                result(FlutterError(code: "UNAVAILABLE", 
                                  message: "ARPhysicsView is no longer available", 
                                  details: nil))
                return
            }
            
            print("ARMethodChannelHandler: Received method call: \(call.method)")
            
            switch call.method {
            case "addPhysicsObject":
                if let args = call.arguments as? [String: Any],
                   let objectData = args["object"] as? [String: Any] {
                    arPhysicsView.handleAddPhysicsObject(objectData: objectData, result: result)
                } else {
                    print("ARMethodChannelHandler: Invalid arguments for addPhysicsObject")
                    result(FlutterError(code: "INVALID_ARGS", 
                                      message: "Invalid arguments for addPhysicsObject", 
                                      details: nil))
                }
                
            case "removePhysicsObject":
                if let args = call.arguments as? [String: Any],
                   let objectId = args["objectId"] as? String {
                    arPhysicsView.handleRemovePhysicsObject(id: objectId, result: result)
                } else {
                    print("ARMethodChannelHandler: Invalid arguments for removePhysicsObject")
                    result(FlutterError(code: "INVALID_ARGS", 
                                      message: "Invalid arguments for removePhysicsObject", 
                                      details: nil))
                }
                
            case "clearPhysicsObjects":
                arPhysicsView.handleClearAllObjects(result: result)
                
            case "screenToWorldPosition":
                if let args = call.arguments as? [String: Any],
                   let x = args["x"] as? Double,
                   let y = args["y"] as? Double {
                    print("ARMethodChannelHandler: Converting screen position: (\(x), \(y))")
                    arPhysicsView.handleScreenToWorldPosition(x: x, y: y, result: result)
                } else {
                    print("ARMethodChannelHandler: Invalid arguments for screenToWorldPosition")
                    result(FlutterError(code: "INVALID_ARGS", 
                                      message: "Invalid arguments for screenToWorldPosition", 
                                      details: nil))
                }
                
            case "setPhysicsParameters":
                if let args = call.arguments as? [String: Any] {
                    arPhysicsView.handleSetPhysicsParameters(args: args, result: result)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", 
                                      message: "Invalid arguments for setPhysicsParameters", 
                                      details: nil))
                }
                
            case "getFps":
                arPhysicsView.handleGetFps(result: result)
                
            default:
                print("ARMethodChannelHandler: Method not implemented: \(call.method)")
                result(FlutterMethodNotImplemented)
            }
        }
        
        print("ARMethodChannelHandler: Method channel registered")
    }
} 