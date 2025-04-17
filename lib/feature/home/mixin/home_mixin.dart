import 'package:flutter/material.dart';
import 'package:lidar_scanner/feature/home/view/home_view.dart';
import 'package:lidar_scanner/feature/scanner/view/scanner_view.dart';
import 'package:lidar_scanner/product/utils/extensions/widget_ext.dart';
import 'package:permission_handler/permission_handler.dart';

mixin HomeMixin on State<HomeView> {
  bool hasLidar = false;
  String deviceInfo = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_init);
  }

  Future<void> _init() async {
    await requestPermissions();
    await _checkDeviceCapabilities();
  }

  Future<void> requestPermissions() async {
    print('Attempting to request camera permission directly...');
    try {
      final status = await Permission.camera.request();
      print('Status after direct request: $status');

      if (status.isGranted) {
        print('Permission granted after direct request.');
      } else if (status.isPermanentlyDenied) {
        print(
            'Permission permanently denied after direct request. Opening settings...');
        await openAppSettings(); // Still try to open settings if permanently denied
      } else {
        print('Permission denied after direct request.');
      }
    } catch (e) {
      print('Error during permission request: $e');
    }
  }

  Future<void> _checkDeviceCapabilities() async {
    final platform = Theme.of(context).platform;

    setState(() {
      if (platform == TargetPlatform.iOS) {
        hasLidar = true;
        deviceInfo = 'iOS device with LiDAR';
      } else {
        hasLidar = false;
        deviceInfo = 'Unsupported platform or non-LiDAR iOS device';
      }
    });
  }

  void pushToScanner() {
    if (!hasLidar) {
      showDialog<void>(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Error'),
          content: Text('You can not scan yet'),
        ),
      );
      return;
    }
    const ScannerView().push(context);
  }
}
