import 'package:flutter/material.dart';
import 'package:lidar_scanner/feature/scanner/mixin/scanner_mixin.dart';

final class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> with ScannerMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner')),
      body: const Center(child: Text('Scanner')),
    );
  }
}
