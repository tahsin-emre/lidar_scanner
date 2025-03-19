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
    await _requestPermissions();
    await _checkDeviceCapabilities();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
  }

  Future<void> _checkDeviceCapabilities() async {
    final platform = Theme.of(context).platform;

    setState(() {
      if (platform == TargetPlatform.iOS) {
        hasLidar = true;
        deviceInfo = 'iOS device with LiDAR';
      } else if (platform == TargetPlatform.android) {
        hasLidar = true;
        deviceInfo = 'Android device with ARCore depth API';
      } else {
        hasLidar = false;
        deviceInfo = 'Unsupported platform';
      }
    });
  }

  void pushToScanner() {
    if (!hasLidar) {
      showDialog<void>(
        context: context,
        builder:
            (context) => const AlertDialog(
              title: Text('Error'),
              content: Text('You can not scan yet'),
            ),
      );
      return;
    }
    const ScannerView().push(context);
  }
}
