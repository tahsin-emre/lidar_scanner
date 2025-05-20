import 'dart:io';

import 'package:flutter/material.dart' hide Material;
import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'package:lidar_scanner/feature/model_viewer/view/model_viewer_view.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

mixin ModelViewerMixin on State<ModelViewerView> {
  late Future<String> tempModelPathFuture;
  late Object? modelObject;
  String? createdTempPath;

  @override
  void initState() {
    super.initState();
    tempModelPathFuture = _prepareTempModelPath(widget.modelPath);
  }

  Future<String> _prepareTempModelPath(String originalPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final originalFileName = p.basename(originalPath);
      final safeFileName = originalFileName.replaceAll(' ', '_');
      final tempPath = p.join(tempDir.path, safeFileName);

      final originalFile = File(originalPath);
      if (!originalFile.existsSync()) {
        throw Exception('Original file not found: $originalPath');
      }

      final tempFile = await originalFile.copy(tempPath);
      createdTempPath = tempFile.path;
      return tempFile.path;
    } catch (error) {
      rethrow;
    }
  }

  @override
  void dispose() {
    if (createdTempPath != null) File(createdTempPath!).deleteSync();
    super.dispose();
  }
}
