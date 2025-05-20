import 'dart:io';

import 'package:flutter/material.dart' hide Material;
import 'package:flutter_cube/flutter_cube.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ModelViewerView extends StatefulWidget {
  const ModelViewerView({
    required this.modelPath,
    super.key,
  });
  final String modelPath;

  @override
  State<ModelViewerView> createState() => _ModelViewerState();
}

class _ModelViewerState extends State<ModelViewerView>
    with TickerProviderStateMixin {
  late Future<String> _tempModelPathFuture;
  String? _createdTempPath;
  bool _isRotating = false;
  final _lastTouchTime = DateTime.now();
  Object? _modelObject;
  Scene? _scene;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _tempModelPathFuture = _prepareTempModelPath(widget.modelPath);
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_handleRotationAnimation);
  }

  void _handleRotationAnimation() {
    if (_isRotating && _modelObject != null && _scene != null) {
      final now = DateTime.now();
      final elapsed = now.difference(_lastTouchTime).inMilliseconds;

      // Only rotate if no touch input recently (1 second)
      if (elapsed > 1000) {
        _modelObject!.rotation.y += 0.01;
        _scene!.update();
      }
    }
  }

  Future<String> _prepareTempModelPath(String originalPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final originalFileName = p.basename(originalPath);
      final safeFileName = originalFileName.replaceAll(' ', '_');
      final tempPath = p.join(tempDir.path, safeFileName);

      debugPrint('Original path: $originalPath');
      debugPrint('Temporary path: $tempPath');

      final originalFile = File(originalPath);
      if (!originalFile.existsSync()) {
        throw Exception('Original file not found: $originalPath');
      }

      final tempFile = await originalFile.copy(tempPath);
      _createdTempPath = tempFile.path;
      debugPrint('File copied successfully to temporary path.');
      return tempFile.path;
    } catch (error) {
      debugPrint('Error preparing temporary model path: $error');
      rethrow;
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    if (_createdTempPath != null) {
      try {
        File(_createdTempPath!).deleteSync();
        debugPrint('Temporary file deleted: $_createdTempPath');
      } on IOException catch (error) {
        debugPrint('Error deleting temporary file: $error');
      }
    }
    super.dispose();
  }

  void _startRotation() {
    if (!_rotationController.isAnimating) {
      _rotationController.repeat();
    }
  }

  void _stopRotation() {
    if (_rotationController.isAnimating) {
      _rotationController.stop();
    }
  }

  void _toggleRotation() {
    setState(() {
      _isRotating = !_isRotating;
      if (_isRotating) {
        _startRotation();
      } else {
        _stopRotation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Model Viewer'),
        actions: [
          IconButton(
            icon: Icon(_isRotating ? Icons.pause : Icons.play_arrow),
            tooltip: _isRotating ? 'Stop Auto-Rotation' : 'Start Auto-Rotation',
            onPressed: _toggleRotation,
          ),
        ],
      ),
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
            final tempModelPath = snapshot.data!;
            return Stack(
              children: [
                Cube(
                  onSceneCreated: (Scene scene) {
                    _scene = scene;
                    _modelObject = Object(
                      fileName: tempModelPath,
                      scale: Vector3(1.5, 1.5, 1.5),
                      lighting: true,
                    );
                    scene.world.add(_modelObject!);

                    // Set up camera and lighting
                    scene.camera.position.setFrom(Vector3(0, 3, 6));
                    scene.camera.target.setFrom(Vector3(0, 0, 0));
                    scene.camera.fov = 45;
                    scene.light.position.setFrom(Vector3(0, 10, 10));
                    scene.light.setColor(Colors.white, 1, 0.7, 0.5);

                    if (_isRotating) {
                      _startRotation();
                    }
                  },
                ),
                // Help text overlay
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(153),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Pan to rotate • Pinch to zoom',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: Text('Unknown state'));
          }
        },
      ),
    );
  }
}
