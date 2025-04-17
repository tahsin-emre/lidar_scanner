import Flutter
import UIKit

class ScannerViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private weak var appDelegate: AppDelegate?

    init(messenger: FlutterBinaryMessenger, appDelegate: AppDelegate) {
        self.messenger = messenger
        self.appDelegate = appDelegate
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let scannerView = ScannerView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
        
        appDelegate?.activeScannerView = scannerView
        
        return scannerView
    }

    // Optional: If you need to pass initialization arguments from Dart to the native view
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
          return FlutterStandardMessageCodec.sharedInstance()
    }
} 