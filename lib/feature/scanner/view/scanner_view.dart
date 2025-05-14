import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_cubit.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_state.dart';
import 'package:lidar_scanner/feature/scanner/mixin/scanner_mixin.dart';
import 'package:lidar_scanner/product/model/export_format.dart';
import 'package:lidar_scanner/product/model/scan_result.dart';
import 'package:lidar_scanner/feature/interactive_physics/view/interactive_physics_view.dart';
import 'package:lidar_scanner/product/utils/extensions/widget_ext.dart';

final class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> with ScannerMixin {
  @override
  void initState() {
    super.initState();
    scannerCubit.checkTalent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Scan'),
        actions: [
          IconButton(
            onPressed: changeScanQuality,
            icon: Icon(scanQualityIcon),
            tooltip: 'Tarama Kalitesi: ${scanQuality.name}',
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildScannerView(),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    return BlocBuilder<ScannerCubit, ScannerState>(
      bloc: scannerCubit,
      builder: (context, state) {
        if (!state.canScan) {
          return const Center(
            child: Text('This device does not support LiDAR scanning'),
          );
        }

        return Stack(
          children: [
            const _Body(),
            if (state.isScanning && state.missingAreas.isNotEmpty)
              _MissingAreasOverlay(areas: state.missingAreas),
          ],
        );
      },
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: BlocBuilder<ScannerCubit, ScannerState>(
        bloc: scannerCubit,
        builder: (context, state) {
          final bool scanningComplete =
              state.canScan && !state.isScanning && state.scanProgress > 0;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Only show these buttons if scanning is complete (has scan data)
              if (scanningComplete) ...[
                // Physics mode button
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.sports_esports),
                    label: const Text('Enter Physics Mode'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => _enterPhysicsMode(context),
                  ),
                ),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Only show export button if scanning is complete
                  if (scanningComplete) ...[
                    FloatingActionButton(
                      heroTag: 'export_fab',
                      onPressed: () async {
                        // Show dialog to get filename
                        final fileName = await _showFileNameDialog(context);
                        if (fileName == null || fileName.isEmpty) {
                          return; // User cancelled or entered empty name
                        }

                        try {
                          final result = await scannerCubit.exportModel(
                            format: ExportFormat.obj,
                            fileName: fileName,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result.isSuccess
                                    ? 'Exported to: ${result.filePath}'
                                    : 'Export failed'),
                              ),
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
                      },
                      child: const Icon(Icons.save_alt),
                    ),
                    const SizedBox(width: 16),
                  ],
                  // Always show the scan button
                  FloatingActionButton(
                    heroTag: 'scan_fab',
                    onPressed: () => _toggleScanning(state),
                    child: Icon(
                      state.isScanning ? Icons.stop : Icons.play_arrow,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleScanning(ScannerState state) async {
    if (!state.canScan) return;
    if (state.isScanning) {
      scannerCubit.stopScanning();
    } else {
      scannerCubit.startScanning(
        scanQuality: scanQuality,
      );
    }
  }

  Future<void> _enterPhysicsMode(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing physics environment...'),
            ],
          ),
        ),
      );

      // Export current scan to temporary file
      final scanPath = await scannerCubit.exportForPhysicsMode();

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      if (scanPath.isNotEmpty) {
        // Navigate to physics mode with the temporary scan
        InteractivePhysicsView(scanPath: scanPath).push(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to prepare physics environment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog if still open
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper function to show the filename dialog
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
                  // Optional: Show error if name is empty
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

final class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: 'com.example.lidarScanner',
      onPlatformViewCreated: _onPlatformViewCreated,
      creationParams: const {
        'initialConfiguration': {
          'enableTapGesture': true,
          'enablePinchGesture': true,
          'enableRotationGesture': true,
        }
      },
      creationParamsCodec: const StandardMessageCodec(),
    );
  }

  static void _onPlatformViewCreated(int id) {
    // Platform view created callback
    debugPrint('Platform view created with id: $id');
  }
}

class _ScanningOverlay extends StatelessWidget {
  const _ScanningOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Column(
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 8),
          Text(
            'Scanning Progress: ${(progress * 100).toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _MissingAreasOverlay extends StatelessWidget {
  const _MissingAreasOverlay({required this.areas});

  final List<ScanArea> areas;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MissingAreasPainter(areas: areas),
      child: const SizedBox.expand(),
    );
  }
}

class MissingAreasPainter extends CustomPainter {
  const MissingAreasPainter({required this.areas});

  final List<ScanArea> areas;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (final area in areas) {
      canvas.drawRect(
        Rect.fromLTWH(
          area.x * size.width,
          area.y * size.height,
          area.width * size.width,
          area.height * size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
