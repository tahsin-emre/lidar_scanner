import 'package:flutter/material.dart';
import 'package:lidar_scanner/feature/home/view/home_view.dart';

mixin HomeMixin on State<HomeView> {
  bool canScan = false;

  void pushToScanner() {
    if (!canScan) {
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
  }
}
