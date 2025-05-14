//
//  AppDelegate.swift
//  Runner
//

import Flutter
import UIKit
import ARKit // Import ARKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  // Add a weak reference to the currently active ScannerView instance
  weak var activeScannerView: ScannerView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let scannerChannel = FlutterMethodChannel(name: "com.example.lidarScanner",
                                              binaryMessenger: controller.binaryMessenger)

    scannerChannel.setMethodCallHandler({
      // Use weak self to avoid retain cycles
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in

      // Safely access self and activeScannerView
      guard let self = self else { return }

      switch call.method {
        case "checkTalent":
          self.checkLidarSupport(result: result)
        case "startScanning":
          self.startScanning(call: call, result: result)
        case "stopScanning":
          self.stopScanning(result: result)
        case "getScanProgress":
          self.getScanProgress(result: result)
        case "exportModel":
          if let args = call.arguments as? [String: Any],
             let format = args["format"] as? String,
             let fileName = args["fileName"] as? String {
            self.exportModel(format: format, fileName: fileName, result: result)
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing format or fileName argument for exportModel", details: nil))
          }
        default:
          result(FlutterMethodNotImplemented)
      }
    })

    // Register the Scanner View Factory
    let scannerFactory = ScannerViewFactory(messenger: controller.binaryMessenger, appDelegate: self)
    print("Registering Scanner View Factory")
    self.registrar(forPlugin: "com.example.lidarScanner.ScannerViewPlugin")!.register(scannerFactory, withId: "com.example.lidarScanner")
    
    // Register the Physics View Factory
    let physicsFactory = PhysicsViewFactory(messenger: controller.binaryMessenger)
    print("Registering Physics View Factory")
    self.registrar(forPlugin: "com.example.lidarScanner.PhysicsViewPlugin")!.register(physicsFactory, withId: "com.example.lidarScanner/physicsView")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Function to check LiDAR support
  private func checkLidarSupport(result: FlutterResult) {
      if #available(iOS 13.4, *) {
          result(ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh))
      } else {
          result(false) // Scene reconstruction requires iOS 13.4+
      }
  }

  // MARK: - Method Channel Handlers (Delegating to activeScannerView)

  private func startScanning(call: FlutterMethodCall, result: FlutterResult) {
      print("AppDelegate: Delegating startScanning to active view")
      guard let scannerView = activeScannerView else {
          result(FlutterError(code: "NO_ACTIVE_VIEW", message: "Scanner view is not available.", details: nil))
          return
      }
      
      if let arguments = call.arguments as? [String: Any],
         let scanQuality = arguments["scanQuality"] as? String,
         let configuration = arguments["configuration"] as? [String: Any] {
          scannerView.startScanning(scanQuality: scanQuality, scanType: "roomScan", configuration: configuration)
      } else {
          // Fallback to default settings if no parameters provided
          scannerView.startScanning(scanQuality: "highQuality", scanType: "roomScan", configuration: [:])
      }
      
      result(nil) // Indicate success
  }

  private func stopScanning(result: FlutterResult) {
      print("AppDelegate: Delegating stopScanning to active view")
      guard let scannerView = activeScannerView else {
          result(FlutterError(code: "NO_ACTIVE_VIEW", message: "Scanner view is not available.", details: nil))
          return
      }
      scannerView.stopScanning()
      result(nil) // Indicate success
  }

  private func getScanProgress(result: FlutterResult) {
      print("AppDelegate: Delegating getScanProgress to active view")
      guard let scannerView = activeScannerView else {
          result(FlutterError(code: "NO_ACTIVE_VIEW", message: "Scanner view is not available.", details: nil))
          return
      }
      let progressData = scannerView.getScanProgress()
      result(progressData)
  }

  private func exportModel(format: String, fileName: String, result: FlutterResult) {
      print("AppDelegate: Delegating exportModel to active view with fileName: \(fileName)")
      guard let scannerView = activeScannerView else {
          result(FlutterError(code: "NO_ACTIVE_VIEW", message: "Scanner view is not available.", details: nil))
          return
      }
      let filePath = scannerView.exportModel(format: format, fileName: fileName)
      result(filePath)
  }
}
