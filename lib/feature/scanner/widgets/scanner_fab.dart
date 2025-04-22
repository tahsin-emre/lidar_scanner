import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_cubit.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_state.dart';
import 'package:lidar_scanner/product/model/export_format.dart';

final class ScannerFab extends StatefulWidget {
  const ScannerFab({super.key});

  @override
  State<ScannerFab> createState() => _ScannerFabState();
}

class _ScannerFabState extends State<ScannerFab> {
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.end,
      spacing: 16,
      children: [
        _ExportFab(),
        _StartFab(),
      ],
    );
  }
}

class _StartFab extends StatelessWidget {
  const _StartFab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScannerCubit, ScannerState>(
      builder: (context, state) {
        final scannerCubit = context.read<ScannerCubit>();
        final canStartScan = state.canScan;
        return FloatingActionButton(
          heroTag: 'scan_fab',
          onPressed: canStartScan
              ? () {
                  if (state.isScanning) {
                    scannerCubit.stopScanning();
                  } else {
                    scannerCubit.startScanning();
                  }
                }
              : null, // Disable button if cannot scan or view not ready
          backgroundColor: canStartScan
              ? Theme.of(context).floatingActionButtonTheme.backgroundColor
              : Colors.grey, // Grey out when disabled
          child: Icon(
            state.isScanning ? Icons.stop : Icons.play_arrow,
          ),
        );
      },
    );
  }
}

class _ExportFab extends StatefulWidget {
  const _ExportFab();

  @override
  State<_ExportFab> createState() => _ExportFabState();
}

class _ExportFabState extends State<_ExportFab> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScannerCubit, ScannerState>(
      builder: (context, state) {
        final scannerCubit = context.read<ScannerCubit>();
        final canStartScan = state.canScan;
        return FloatingActionButton(
          heroTag: 'export_fab',
          onPressed: canStartScan
              ? () async {
                  final fileName = await _showFileNameDialog(context);
                  if (fileName == null || fileName.isEmpty) return;
                  try {
                    final filePath = await scannerCubit.exportModel(
                      ExportFormat.obj,
                      fileName,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Exported to: $filePath')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Export failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              : null,
          backgroundColor: canStartScan
              ? Theme.of(context).floatingActionButtonTheme.backgroundColor
              : Colors.grey,
          child: const Icon(Icons.save_alt),
        );
      },
    );
  }

  Future<String?> _showFileNameDialog(BuildContext context) async {
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
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop(name);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File name cannot be empty')),
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
}
