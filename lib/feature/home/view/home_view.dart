import 'package:flutter/material.dart';
import 'package:lidar_scanner/feature/home/mixin/home_mixin.dart';
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

          // Ana tarama butonu
          _StartScanButton(
            icon: Icons.bedroom_parent,
            label: 'Scan Room',
            onTap: pushToScanner,
          ).sliver(),

          const SizedBox(height: 16).sliver(),

          // Bilgilendirme başlığı
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Interactive Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Yeni özellikler hakkında kısa açıklama
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'You can view your saved scans and use the interactive physics mode to play with virtual objects in your scanned environment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16).sliver(),

          // Kayıtlı taramaları görüntüleme butonu
          _FeatureButton(
            icon: Icons.folder_open,
            label: 'View Saved Scans',
            onTap: () {
              const SavedScansView().push(context);
            },
          ).sliver(),

          const SizedBox(height: 8).sliver(),

          // Interactive Physics demo butonu
          _FeatureButton(
            icon: Icons.sports_esports,
            label: 'Interactive Physics Demo',
            onTap: () {
              const SavedScansView().push(context);
            },
          ).sliver(),

          const SizedBox(height: 32).sliver(),
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

// Yeni özellik butonu
final class _FeatureButton extends StatelessWidget {
  const _FeatureButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
