import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_cubit.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_state.dart';
import 'package:lidar_scanner/feature/scanner/mixin/scanner_mixin.dart';
import 'package:lidar_scanner/product/model/scan_result.dart';

final class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> with ScannerMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environment Scan'),
        actions: [
          IconButton(
            onPressed: changeScanQuality,
            icon: Icon(scanQualityIcon),
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
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (state.canScan && !state.isScanning) ...[
                    FloatingActionButton(
                      onPressed: () => exportModel(context),
                      child: const Icon(Icons.save_alt),
                    ),
                    const SizedBox(width: 16),
                  ],
                  FloatingActionButton(
                    onPressed: () => toggleScanning(state),
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
}

final class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: 'com.example.lidarScanner',
      onPlatformViewCreated: (id) {},
      creationParamsCodec: const StandardMessageCodec(),
      creationParams: const {
        'initialConfiguration': {
          'enableTapGesture': true,
          'enablePinchGesture': true,
          'enableRotationGesture': true,
        },
      },
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
      ..color = Colors.red.withValues(red: 255, green: 0, blue: 0, alpha: 77)
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
