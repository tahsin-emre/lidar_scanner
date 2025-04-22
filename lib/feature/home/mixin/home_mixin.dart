import 'package:flutter/material.dart';
import 'package:lidar_scanner/feature/home/view/home_view.dart';
import 'package:lidar_scanner/feature/scanner/view/scanner_view.dart';
import 'package:lidar_scanner/product/utils/enum/scan_type.dart';
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
    final status = await Permission.camera.request();
    if (status.isGranted) return;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
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

  void pushToScanner(ScanType scanType) {
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
    ScannerView(scanType: scanType).push(context);
  }
}
