import 'package:flutter/material.dart';
import 'package:lidar_scanner/product/utils/enum/scan_type.dart';

class ScannerInitializeCard extends StatelessWidget {
  const ScannerInitializeCard({required this.scanType, super.key});
  final ScanType scanType;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Start to scan ${scanType.name}'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
