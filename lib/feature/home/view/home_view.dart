import 'package:flutter/material.dart';
import 'package:lidar_scanner/feature/ar_physics/view/ar_physics_view.dart';
import 'package:lidar_scanner/feature/home/mixin/home_mixin.dart';
import 'package:lidar_scanner/feature/model_viewer/view/model_viewer_view.dart';
import 'package:lidar_scanner/feature/saved_scans/view/saved_scans_view.dart';
import 'package:lidar_scanner/product/utils/extensions/widget_ext.dart';

part '../widgets/home_header.dart';

final class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with HomeMixin {
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
          _StartScanButton(
            icon: Icons.bedroom_parent,
            label: 'Scan Room',
            onTap: pushToScanner,
          ).sliver(),
          _StartScanButton(
            icon: Icons.sports_volleyball,
            label: 'AR Physics',
            onTap: () {
              const ArPhysicsView().push(context);
            },
          ).sliver(),
          _StartScanButton(
            icon: Icons.view_in_ar,
            label: '3D Model Viewer',
            onTap: () {
              const ModelViewerView().push(context);
            },
          ).sliver(),
          _ViewSavedScansButton(() {
            const SavedScansView().push(context);
          }).sliver(),
        ],
      ),
    );
  }
}

final class _StartScanButton extends StatelessWidget {
  const _StartScanButton({
    required this.onTap,
    required this.label,
    required this.icon,
  });
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: onTap,
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
