import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart'; // Use flutter_cube
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart'; // For temp directory

// Convert back to StatefulWidget for temp file handling
class ModelViewerView extends StatefulWidget {
  const ModelViewerView({
    required this.modelPath,
    super.key,
  });
  final String modelPath;

  @override
  State<ModelViewerView> createState() => _ModelViewerState();
}

class _ModelViewerState extends State<ModelViewerView> {
  // Store the future that copies the file and returns the temp path
  late Future<String> _tempModelPathFuture;
  String? _createdTempPath; // Store the path to delete it later

  @override
  void initState() {
    super.initState();
    _tempModelPathFuture = _prepareTempModelPath(widget.modelPath);
  }

  Future<String> _prepareTempModelPath(String originalPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final originalFileName = p.basename(originalPath);
      // Create a safe filename by replacing spaces
      final safeFileName = originalFileName.replaceAll(' ', '_');
      final tempPath = p.join(tempDir.path, safeFileName);

      debugPrint('Original path: $originalPath');
      debugPrint('Temporary path: $tempPath');

      final originalFile = File(originalPath);
      if (!await originalFile.exists()) {
        throw Exception('Original file not found: $originalPath');
      }

      // Copy the file to the temporary path
      final tempFile = await originalFile.copy(tempPath);
      _createdTempPath = tempFile.path; // Store for deletion
      debugPrint('File copied successfully to temporary path.');
      return tempFile.path;
    } catch (e) {
      debugPrint('Error preparing temporary model path: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    // Delete the temporary file when the widget is disposed
    if (_createdTempPath != null) {
      final tempFile = File(_createdTempPath!);
      tempFile.exists().then((exists) {
        if (exists) {
          tempFile.delete().then((_) {
            debugPrint('Temporary file deleted: $_createdTempPath');
          }).catchError((e) {
            debugPrint('Error deleting temporary file: $e');
          });
        }
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the original filename for the AppBar title
    final originalFileName = p.basename(widget.modelPath);

    return Scaffold(
      appBar: AppBar(title: Text(originalFileName)),
      // Use FutureBuilder to wait for the temporary file path
      body: FutureBuilder<String>(
        future: _tempModelPathFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error preparing model file:\n${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (snapshot.hasData) {
            // Temporary path is ready, build the Cube widget
            final tempModelPath = snapshot.data!;
            final object = Object(fileName: tempModelPath, lighting: true);
            return Cube(
              onSceneCreated: (Scene scene) {
                scene.world.add(object);
                // You might need to adjust camera/light settings again for flutter_cube
                scene.camera.position.setFrom(Vector3(0, 5, 15));
                scene.camera.target.setFrom(Vector3(0, 0, 0));
                scene.camera.zoom = 1.0;
                scene.light.position.setFrom(Vector3(10, 20, 10));
                scene.light.setColor(Colors.white, 0.8, 0.4, 0.2);
              },
            );
          } else {
            // Should not happen
            return const Center(child: Text('Unknown state'));
          }
        },
      ),
    );
  }
}
