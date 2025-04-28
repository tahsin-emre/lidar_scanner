import 'package:flutter/material.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_cubit.dart';
import 'package:lidar_scanner/feature/scanner/view/scanner_view.dart';
import 'package:lidar_scanner/product/di/locator.dart';
import 'package:lidar_scanner/product/utils/enum/scan_quality.dart';

mixin ScannerMixin on State<ScannerView> {
  late final scannerCubit = locator<ScannerCubit>();
  ScanQuality scanQuality = ScanQuality.lowQuality;

  @override
  void initState() {
    super.initState();
    scannerCubit.checkTalent();
  }

  void changeScanQuality() {
    if (scanQuality == ScanQuality.lowQuality) {
      scanQuality = ScanQuality.highQuality;
    } else if (scanQuality == ScanQuality.highQuality) {
      scanQuality = ScanQuality.lowQuality;
    }
    setState(() {});
  }

  IconData get scanQualityIcon {
    return switch (scanQuality) {
      ScanQuality.lowQuality => Icons.speed,
      ScanQuality.highQuality => Icons.zoom_in,
    };
  }
}
