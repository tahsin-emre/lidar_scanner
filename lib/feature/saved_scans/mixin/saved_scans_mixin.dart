import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lidar_scanner/feature/saved_scans/view/saved_scans_view.dart';
import 'package:path_provider/path_provider.dart';

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

    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();
    final objFiles = files.where((file) => file.path.endsWith('.obj')).toList();

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

    scanFilesList.sort((a, b) => b.creationDate.compareTo(a.creationDate));

    setState(() {
      scanFiles = scanFilesList;
      isLoading = false;
    });
  }
}

final class ScanFile {
  ScanFile({
    required this.file,
    required this.fileName,
    required this.creationDate,
    required this.formattedDate,
  });

  final FileSystemEntity file;
  final String fileName;
  final DateTime creationDate;
  final String formattedDate;
}
