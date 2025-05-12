import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lidar_scanner/feature/home/mixin/home_mixin.dart';
import 'package:lidar_scanner/feature/saved_scans/view/saved_scans_view.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_cubit.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_state.dart';
import 'package:lidar_scanner/product/di/locator.dart';
import 'package:lidar_scanner/product/utils/enum/scan_type.dart';
import 'package:lidar_scanner/product/utils/extensions/widget_ext.dart';

part '../widgets/home_header.dart';

final class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with HomeMixin {
  late final ScannerCubit scannerCubit;

  @override
  void initState() {
    super.initState();
    scannerCubit = locator<ScannerCubit>();
    scannerCubit.checkTalent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Lidar Scanner'),
            elevation: 0,
          ),
          _Header(hasLidar: hasLidar, deviceInfo: deviceInfo).sliver(),
          Row(
            children: [
              _StartScanButton(
                icon: Icons.wine_bar,
                label: 'Scan Object',
                scanType: ScanType.objectScan,
                onTap: pushToScanner,
              ),
              _StartScanButton(
                icon: Icons.bedroom_parent,
                label: 'Scan Room',
                scanType: ScanType.roomScan,
                onTap: pushToScanner,
              ),
            ],
          ).sliver(),
          _EntertainmentModeButton(scannerCubit).sliver(),
          _ViewSavedScansButton(() {
            const SavedScansView().push(context);
          }).sliver(),
        ],
      ),
    );
  }
}

final class _EntertainmentModeButton extends StatelessWidget {
  const _EntertainmentModeButton(this.scannerCubit);
  final ScannerCubit scannerCubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScannerCubit, ScannerState>(
      bloc: scannerCubit,
      builder: (context, state) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: InkWell(
            onTap: () {
              if (state.isEntertainmentModeActive) {
                scannerCubit.toggleEntertainmentMode();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EntertainmentModeView(),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.celebration,
                    size: 30,
                    color: const Color(0xffFFD700),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Entertainment Mode',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _StartScanButton extends StatelessWidget {
  const _StartScanButton({
    required this.onTap,
    required this.scanType,
    required this.label,
    required this.icon,
  });
  final ValueChanged<ScanType> onTap;
  final ScanType scanType;
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: () => onTap(scanType),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: const Color(0xff29fcfe),
                ),
                const SizedBox(height: 8),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _ViewSavedScansButton extends StatelessWidget {
  const _ViewSavedScansButton(this.onTap);
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open),
          SizedBox(width: 8),
          Text('View Saved Scans'),
        ],
      ),
    );
  }
}

// Entertainment Mode View
class EntertainmentModeView extends StatefulWidget {
  const EntertainmentModeView({super.key});

  @override
  State<EntertainmentModeView> createState() => _EntertainmentModeViewState();
}

class _EntertainmentModeViewState extends State<EntertainmentModeView> {
  late final ScannerCubit scannerCubit;
  bool isRaining = false;
  String debugMessage = '';
  final GlobalKey<_ARViewState> _arViewKey = GlobalKey();
  bool _arViewReady = false;

  @override
  void initState() {
    super.initState();
    scannerCubit = locator<ScannerCubit>();
    // Entertainment mode will be started after the AR view is ready
  }

  @override
  void dispose() {
    _stopEntertainmentMode();
    super.dispose();
  }

  void _onARViewCreated() {
    setState(() {
      _arViewReady = true;
      debugMessage = 'AR View initialized, waiting for system to be ready...';
    });

    // Use a longer delay to ensure the native view is fully set up
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        debugMessage = 'Starting entertainment mode...';
      });
      _startEntertainmentMode();
    });
  }

  Future<void> _startEntertainmentMode() async {
    if (!_arViewReady) {
      setState(() {
        debugMessage = 'Error: AR View not ready yet';
      });
      return;
    }

    try {
      await scannerCubit.toggleEntertainmentMode();
      setState(() {
        debugMessage = 'Entertainment mode started';
      });
    } catch (e) {
      setState(() {
        debugMessage =
            'Error starting entertainment mode: $e\nRetrying in 3 seconds...';
      });

      // Retry after a delay
      Future.delayed(const Duration(seconds: 3), () {
        _retryEntertainmentMode();
      });
    }
  }

  // Retry entertainment mode activation
  Future<void> _retryEntertainmentMode() async {
    try {
      setState(() {
        debugMessage = 'Retrying entertainment mode activation...';
      });
      await scannerCubit.toggleEntertainmentMode();
      setState(() {
        debugMessage = 'Entertainment mode started successfully on retry';
      });
    } catch (e) {
      setState(() {
        debugMessage = 'Still failing. Error: $e';
      });
    }
  }

  Future<void> _stopEntertainmentMode() async {
    try {
      if (scannerCubit.state.isEntertainmentModeActive) {
        await scannerCubit.toggleEntertainmentMode();
      }
    } catch (e) {
      print('Error stopping entertainment mode: $e');
    }
  }

  Future<void> _toggleCoinRain() async {
    try {
      setState(() {
        isRaining = !isRaining;
        debugMessage = 'Toggling rain to: $isRaining';
      });

      // The continuous spawning is now handled in the native code
      // One tap will toggle continuous rain on/off
      await scannerCubit.spawnEntertainmentObject(
        assetName:
            'fallback', // Use fallback object instead of trying to load coin.usdz
        properties: {'continuous': true},
      );
    } catch (e) {
      setState(() {
        debugMessage = 'Error toggling rain: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entertainment Mode'),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // AR View
          _ARView(key: _arViewKey, onViewCreated: _onARViewCreated),

          // Debug message
          if (debugMessage.isNotEmpty)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black.withOpacity(0.7),
                child: Text(
                  debugMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),

          // Controls
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isRaining ? 'Rain is ON' : 'Start the Rain!',
                  style: TextStyle(
                    color: isRaining ? Colors.amber : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                FloatingActionButton.large(
                  backgroundColor: isRaining ? Colors.amber : Colors.blue,
                  onPressed: _arViewReady ? _toggleCoinRain : null,
                  child: Icon(
                    isRaining ? Icons.money_off : Icons.attach_money,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ARView extends StatefulWidget {
  const _ARView({Key? key, required this.onViewCreated}) : super(key: key);
  final VoidCallback onViewCreated;

  @override
  State<_ARView> createState() => _ARViewState();
}

class _ARViewState extends State<_ARView> {
  @override
  void initState() {
    super.initState();
    // Don't call onViewCreated here, wait for the platform view to be created
  }

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

  void _onPlatformViewCreated(int id) {
    // Platform view created callback
    debugPrint('Platform view created with id: $id');

    // Notify the parent that the view is ready
    widget.onViewCreated();
  }
}
