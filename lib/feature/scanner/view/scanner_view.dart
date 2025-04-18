import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_cubit.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_state.dart';
import 'package:lidar_scanner/feature/scanner/mixin/scanner_mixin.dart';
import 'package:lidar_scanner/product/model/export_format.dart';
import 'package:lidar_scanner/product/model/scan_result.dart';

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
      appBar: AppBar(title: const Text('3D Scanner')),
      body: BlocBuilder<ScannerCubit, ScannerState>(
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
              if (state.isScanning) ...[
                _ScanningOverlay(progress: state.scanProgress),
                if (state.missingAreas.isNotEmpty)
                  _MissingAreasOverlay(areas: state.missingAreas),
              ],
            ],
          );
        },
      ),
      floatingActionButton: BlocBuilder<ScannerCubit, ScannerState>(
        bloc: scannerCubit,
        builder: (context, state) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (state.canScan && !state.isScanning) ...[
                FloatingActionButton(
                  heroTag: 'export_fab',
                  onPressed: () async {
                    try {
                      final filePath =
                          await scannerCubit.exportModel(ExportFormat.obj);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Exported to: $filePath'),
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
              FloatingActionButton(
                heroTag: 'scan_fab',
                onPressed: () {
                  if (!state.canScan) return;
                  if (state.isScanning) {
                    scannerCubit.stopScanning();
                  } else {
                    scannerCubit.startScanning();
                  }
                },
                child: Icon(
                  state.isScanning ? Icons.stop : Icons.play_arrow,
                ),
              ),
            ],
          );
        },
      ),
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
