//
//  PhysicsViewFactory.swift
//  Runner
//

import Foundation
import UIKit
import Flutter

class PhysicsViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private var views = [Int64: PhysicsView]()
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
        
        print("PhysicsViewFactory: initializing")
        
        // Register method channel for physics operations
        let channel = FlutterMethodChannel(name: "com.example.lidarScanner/physics", binaryMessenger: messenger)
        channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else { return }
            self.handleMethodCall(call, result: result)
        }
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        print("PhysicsViewFactory: creating view with ID \(viewId)")
        
        let physicsView = PhysicsView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
        
        // Store view for later access via method channel
        views[viewId] = physicsView
        print("PhysicsViewFactory: stored view with ID \(viewId), total views: \(views.count)")
        
        return physicsView
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
    
    // MARK: - Method Channel Handler
    
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("PhysicsViewFactory: received method call: \(call.method)")
        
        guard let args = call.arguments as? [String: Any],
              let viewIdNumber = args["viewId"] as? Int else {
            print("PhysicsViewFactory: missing viewId in arguments")
            result(FlutterError(code: "INVALID_VIEW_ID", message: "viewId not found in arguments", details: nil))
            return
        }
        
        let viewId = Int64(viewIdNumber)
        
        guard let physicsView = views[viewId] else {
            print("PhysicsViewFactory: no view found for ID \(viewId). Available IDs: \(views.keys)")
            result(FlutterError(code: "INVALID_VIEW_ID", message: "No physics view found for ID \(viewId)", details: nil))
            return
        }
        
        print("PhysicsViewFactory: handling method \(call.method) for view ID \(viewId)")
        
        switch call.method {
        case "initializePhysics":
            guard let scanPath = args["scanPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing scan path", details: nil))
                return
            }
            
            physicsView.initializePhysics(scanPath: scanPath)
            result(nil)
            
        case "screenToWorldPosition":
            guard let x = args["x"] as? Double,
                  let y = args["y"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing x, y coordinates", details: nil))
                return
            }
            
            let position = physicsView.screenToWorldPosition(x: x, y: y)
            result(position)
            
        case "addPhysicsObject":
            guard let objectData = args["object"] as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing object data", details: nil))
                return
            }
            
            let success = physicsView.addPhysicsObject(objectData: objectData)
            result(success)
            
        case "removePhysicsObject":
            guard let objectId = args["objectId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing object ID", details: nil))
                return
            }
            
            let success = physicsView.removePhysicsObject(objectId: objectId)
            result(success)
            
        case "clearPhysicsObjects":
            physicsView.clearPhysicsObjects()
            result(nil)
            
        case "applyForce":
            guard let objectId = args["objectId"] as? String,
                  let force = args["force"] as? [Double],
                  let position = args["position"] as? [Double] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing force parameters", details: nil))
                return
            }
            
            physicsView.applyForce(objectId: objectId, force: force, position: position)
            result(nil)
            
        case "adjustModelPosition":
            guard let deltaX = args["deltaX"] as? Double,
                  let deltaY = args["deltaY"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing deltaX or deltaY parameters for adjustModelPosition", details: nil))
                return
            }
            
            let success = physicsView.adjustModelPosition(screenDeltaX: deltaX, screenDeltaY: deltaY)
            result(success)
            
        case "rotateModelY":
            guard let angle = args["angle"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing angle parameter", details: nil))
                return
            }
            
            let success = physicsView.rotateModelY(angle: angle)
            result(success)
            
        case "zoomModel":
            guard let scaleFactor = args["scaleFactor"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing scaleFactor parameter", details: nil))
                return
            }
            
            print("PhysicsViewFactory: Zooming model with scale factor \(scaleFactor) for view ID \(viewId)")
            let success = physicsView.zoomModel(scaleFactor: scaleFactor)
            result(success)
            
        case "resetModelPositionToOrigin":
            let success = physicsView.resetModelPositionToOrigin()
            result(success)
            
        case "getFps":
            let fps = physicsView.getFps()
            result(fps)
            
        case "setPhysicsParameters":
            physicsView.setPhysicsParameters(parameters: args)
            result(nil)
            
        case "disposePhysics":
            views.removeValue(forKey: viewId)
            result(nil)
            
        case "setMeshVisibility":
            guard let visible = args["visible"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing visibility parameter", details: nil))
                return
            }
            
            print("PhysicsViewFactory: Setting mesh visibility to \(visible) for view ID \(viewId)")
            let success = physicsView.setMeshVisibility(visible: visible)
            
            // If we're making the mesh invisible, we should make sure we're still using LiDAR for occlusion
            if !visible && success {
                // This ensures LiDAR real-world occlusion is still active even with invisible scanned model
                print("PhysicsViewFactory: Mesh hidden - confirming LiDAR occlusion is active")
                physicsView.confirmLiDAREnabled()
            }
            
            print("PhysicsViewFactory: Mesh visibility update result: \(success)")
            result(success)
            
        case "getCameraPosition":
            let position = physicsView.getCameraPosition()
            print("PhysicsViewFactory: Getting camera position for view ID \(viewId): \(position)")
            result(position)
            
        case "setSelectedObject":
            guard let type = args["type"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing type parameter", details: nil))
                return
            }
            
            print("PhysicsViewFactory: Setting selected object type to \(type) for view ID \(viewId)")
            let success = physicsView.setSelectedObject(type: type)
            result(success)
            
        case "startObjectRain":
            let count = args["count"] as? Int ?? 20
            let height = Float(args["height"] as? Double ?? 2.0)
            
            print("PhysicsViewFactory: Starting object rain with \(count) objects at height \(height) for view ID \(viewId)")
            let success = physicsView.startObjectRain(count: count, height: height)
            result(success)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
} 