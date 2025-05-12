import 'dart:io';

import 'package:flutter/material.dart' hide Material;
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
      try {
        File(_createdTempPath!).deleteSync();
        debugPrint('Temporary file deleted: $_createdTempPath');
      } catch (e) {
        debugPrint('Error deleting temporary file: $e');
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Point Cloud Viewer'),
      ),
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

                // Convert mesh to points
                final vertices = object.mesh.vertices;
                final points = <Object>[];

                // Create a point for each vertex
                for (var i = 0; i < vertices.length; i += 3) {
                  final point = Object(
                    mesh: Mesh(
                      vertices: [vertices[i], vertices[i + 1], vertices[i + 2]],
                      indices: [Polygon(0, 1, 2)],
                    ),
                  );
                  final material = Material()..diffuse = fromColor(Colors.blue);
                  point.mesh.material = material;
                  points.add(point);
                }

                // Remove original object and add points
                scene.world.remove(object);
                for (final point in points) {
                  scene.world.add(point);
                }

                // Adjust camera settings
                scene.camera.position.setFrom(Vector3(0, 5, 15));
                scene.camera.target.setFrom(Vector3(0, 0, 0));
                scene.camera.zoom = 1.0;

                // Add lighting
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
