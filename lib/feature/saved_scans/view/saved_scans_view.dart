import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lidar_scanner/feature/model_viewer/view/model_viewer_view.dart';
import 'package:lidar_scanner/product/utils/extensions/widget_ext.dart';
import 'package:path_provider/path_provider.dart';

class SavedScansView extends StatefulWidget {
  const SavedScansView({super.key});

  @override
  State<SavedScansView> createState() => _SavedScansViewState();
}

class _SavedScansViewState extends State<SavedScansView> {
  List<FileSystemEntity> _objFiles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedScans();
  }

  Future<void> _loadSavedScans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      setState(() {
        // Filter for .obj files (adjust if using other formats)
        _objFiles = files.where((file) => file.path.endsWith('.obj')).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load saved scans: $e';
        _isLoading = false;
      });
      print(_error); // Log the error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Scans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavedScans,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_objFiles.isEmpty) {
      return const Center(
        child: Text(
          'No saved scans found.\nExport a scan from the Scanner screen.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: _objFiles.length,
      itemBuilder: (context, index) {
        final file = _objFiles[index];
        final fileName = file.path.split('/').last; // Get simple filename
        return ListTile(
          leading: const Icon(Icons.view_in_ar), // Or Icons.folder_zip
          title: Text(fileName),
          subtitle: Text('Path: ${file.path}'), // Show full path if needed
          onTap: () {
            ModelViewerView(modelPath: file.path).push(context);
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
        await _loadSavedScans(); // Refresh list after deleting
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
