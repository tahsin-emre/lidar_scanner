import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lidar_scanner/feature/saved_scans/view/saved_scans_view.dart';
import 'package:path_provider/path_provider.dart';

mixin SavedScansMixin on State<SavedScansView> {
  List<FileSystemEntity> objFiles = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    Future.microtask(loadSavedScans);
  }

  Future<void> loadSavedScans() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      setState(() {
        // Filter for .obj files (adjust if using other formats)
        objFiles = files.where((file) => file.path.endsWith('.obj')).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load saved scans: $e';
        isLoading = false;
      });
      print(error); // Log the error
    }
  }
}
