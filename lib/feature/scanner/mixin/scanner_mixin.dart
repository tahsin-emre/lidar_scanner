import 'package:flutter/material.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_cubit.dart';
import 'package:lidar_scanner/feature/scanner/view/scanner_view.dart';
import 'package:lidar_scanner/product/di/locator.dart';

mixin ScannerMixin on State<ScannerView> {
  late final scannerCubit = locator<ScannerCubit>();

  @override
  void initState() {
    super.initState();
    scannerCubit.checkTalent();
  }
}
