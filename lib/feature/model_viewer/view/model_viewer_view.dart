import 'package:flutter/material.dart' hide Material;
import 'package:flutter_cube/flutter_cube.dart';
import 'package:lidar_scanner/feature/model_viewer/mixin/model_viewer_mixin.dart';

class ModelViewerView extends StatefulWidget {
  const ModelViewerView({
    required this.modelPath,
    super.key,
  });
  final String modelPath;

  @override
  State<ModelViewerView> createState() => _ModelViewerState();
}

class _ModelViewerState extends State<ModelViewerView> with ModelViewerMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('3D Model Viewer')),
      body: FutureBuilder<String>(
        future: tempModelPathFuture,
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
                // @Generated by Gemini-2.5-Pro
                Cube(
                  onSceneCreated: (Scene scene) {
                    modelObject = Object(
                      fileName: tempModelPath,
                      scale: Vector3(1.5, 1.5, 1.5),
                      lighting: true,
                    );
                    scene.world.add(modelObject!);
                    scene.camera.position.setFrom(Vector3(0, 3, 6));
                    scene.camera.target.setFrom(Vector3(0, 0, 0));
                    scene.camera.fov = 45;
                    scene.light.position.setFrom(Vector3(0, 10, 10));
                    scene.light.setColor(Colors.white, 1, 0.7, 0.5);
                  },
                ),
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
