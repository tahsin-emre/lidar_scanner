import 'package:flutter/material.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_cubit.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_state.dart';
import 'package:lidar_scanner/feature/scanner/view/scanner_view.dart';
import 'package:lidar_scanner/product/di/locator.dart';
import 'package:lidar_scanner/product/model/export_format.dart';
import 'package:lidar_scanner/product/utils/enum/scan_quality.dart';

mixin ScannerMixin on State<ScannerView> {
  late final scannerCubit = locator<ScannerCubit>();
  ScanQuality scanQuality = ScanQuality.highQuality;

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

  Future<void> toggleScanning(ScannerState state) async {
    if (!state.canScan) return;
    if (state.isScanning) {
      await scannerCubit.stopScanning();
    } else {
      await scannerCubit.startScanning(
        scanQuality: scanQuality,
      );
    }
  }

  Future<void> exportModel(BuildContext context) async {
    final fileName = await showFileNameDialog(context);
    if (!mounted || fileName == null || fileName.isEmpty) {
      return;
    }

    try {
      final result = await scannerCubit.exportModel(
        format: ExportFormat.obj,
        fileName: fileName,
      );

      if (!mounted) return;

      showSnackBar(
        result.isSuccess ? 'Exported to: ${result.filePath}' : 'Export failed',
      );
    } on Exception catch (e) {
      if (!mounted) return;
      showSnackBar('Export failed: $e');
    }
  }

  Future<String?> showFileNameDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter File Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'scan_name',
              suffixText: '.obj',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop(name);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File name cannot be empty'),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
