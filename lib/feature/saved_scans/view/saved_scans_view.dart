import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lidar_scanner/feature/interactive_physics/view/interactive_physics_view.dart';
import 'package:lidar_scanner/feature/model_viewer/view/model_viewer_view.dart';
import 'package:lidar_scanner/feature/saved_scans/mixin/saved_scans_mixin.dart';
import 'package:lidar_scanner/product/utils/extensions/widget_ext.dart';

class SavedScansView extends StatefulWidget {
  const SavedScansView({super.key});

  @override
  State<SavedScansView> createState() => _SavedScansViewState();
}

class _SavedScansViewState extends State<SavedScansView> with SavedScansMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Scans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadSavedScans,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (scanFiles.isEmpty) {
      return const Center(
        child: Text(
          'No saved scans found.\nExport a scan from the Scanner screen.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: scanFiles.length,
      itemBuilder: (context, index) {
        final scanFile = scanFiles[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.view_in_ar),
                title: Text(scanFile.fileName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Created: ${scanFile.formattedDate}'),
                    Text(
                      scanFile.file.path,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
              ButtonBar(
                alignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.visibility,
                    label: 'View',
                    onPressed: () {
                      ModelViewerView(modelPath: scanFile.file.path)
                          .push(context);
                    },
                  ),
                  _ActionButton(
                    icon: Icons.sports_esports,
                    label: 'Physics Mode',
                    onPressed: () {
                      InteractivePhysicsView(scanPath: scanFile.file.path)
                          .push(context);
                    },
                  ),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: Colors.redAccent,
                    onPressed: () => _deleteScan(scanFile),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteScan(ScanFile scanFile) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Scan?'),
          content:
              Text('Are you sure you want to delete ${scanFile.fileName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await scanFile.file.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${scanFile.fileName} deleted.')),
        );
        await loadSavedScans(); // Refresh list after deleting
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      onPressed: onPressed,
    );
  }
}
