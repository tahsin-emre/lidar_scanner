import 'package:flutter/material.dart';
import 'package:lidar_scanner/feature/home/mixin/home_mixin.dart';
import 'package:lidar_scanner/product/utils/extensions/widget_ext.dart';

final class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with HomeMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lidar Scanner')),
      body: CustomScrollView(
        slivers: [
          _Header(hasLidar: hasLidar, deviceInfo: deviceInfo).sliver(),
          _PermissionButton(onTap: requestPermissions).sliver(),
          _StartScanButton(pushToScanner).sliver(),
        ],
      ),
    );
  }
}

class _PermissionButton extends StatelessWidget {
  const _PermissionButton({required this.onTap});
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
          Icon(Icons.camera),
          SizedBox(width: 8),
          Text('Request Permission'),
        ],
      ),
    );
  }
}

final class _StartScanButton extends StatelessWidget {
  const _StartScanButton(this.onTap);
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
          Icon(Icons.camera),
          SizedBox(width: 8),
          Text('Start New Scan'),
        ],
      ),
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header({required this.hasLidar, required this.deviceInfo});
  final bool hasLidar;
  final String deviceInfo;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.view_in_ar, size: 100, color: Colors.blue),
        const SizedBox(height: 24),
        Text(
          '3D Object Scanner',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Scan real-world objects and create 3D models',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Device Capabilities',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasLidar ? Icons.check_circle : Icons.error,
                      color: hasLidar ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: Text(deviceInfo)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
