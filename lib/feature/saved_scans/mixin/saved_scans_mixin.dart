import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lidar_scanner/feature/saved_scans/view/saved_scans_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

mixin SavedScansMixin on State<SavedScansView> {
  List<ScanFile> scanFiles = [];
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

      // Filter for .obj files
      final objFiles =
          files.where((file) => file.path.endsWith('.obj')).toList();

      // Convert to ScanFile objects with metadata
      final scanFilesList = <ScanFile>[];
      for (final file in objFiles) {
        final stat = await FileStat.stat(file.path);
        scanFilesList.add(
          ScanFile(
            file: file,
            fileName: file.path.split('/').last,
            creationDate: stat.changed,
            formattedDate:
                DateFormat('MMM dd, yyyy - HH:mm').format(stat.changed),
          ),
        );
      }

      // Sort by date (newest first)
      scanFilesList.sort((a, b) => b.creationDate.compareTo(a.creationDate));

      setState(() {
        scanFiles = scanFilesList;
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

/// Model class for scan files with metadata
class ScanFile {
  final FileSystemEntity file;
  final String fileName;
  final DateTime creationDate;
  final String formattedDate;

  ScanFile({
    required this.file,
    required this.fileName,
    required this.creationDate,
    required this.formattedDate,
  });
}
