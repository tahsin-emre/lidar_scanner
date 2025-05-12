import 'dart:io';

import 'package:flutter/material.dart';
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
    if (objFiles.isEmpty) {
      return const Center(
        child: Text(
          'No saved scans found.\nExport a scan from the Scanner screen.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: objFiles.length,
      itemBuilder: (context, index) {
        final file = objFiles[index];
        final fileName = file.path.split('/').last; // Get simple filename
        return ListTile(
          leading: const Icon(Icons.view_in_ar), // Or Icons.folder_zip
          title: Text(fileName),
          subtitle: Text('Path: ${file.path}'), // Show full path if needed
          onTap: () {
            ModelViewerView().push(context);
          },
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Scan',
            onPressed: () => _deleteScan(file),
          ),
        );
      },
    );
  }

  Future<void> _deleteScan(FileSystemEntity file) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Scan?'),
          content: Text(
              'Are you sure you want to delete ${file.path.split('/').last}?'),
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
        await file.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${file.path.split('/').last} deleted.')),
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
