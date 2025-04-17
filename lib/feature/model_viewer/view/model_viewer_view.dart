import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ModelViewerView extends StatelessWidget {
  const ModelViewerView({super.key, required this.modelPath});

  final String modelPath;

  @override
  Widget build(BuildContext context) {
    // Extract filename for the AppBar title
    final fileName = modelPath.split('/').last;

    return Scaffold(
      appBar: AppBar(title: Text(fileName)),
      body: ModelViewer(
        src: 'file://$modelPath', // Important: Use the file:// scheme
        alt: "A 3D model of $fileName",
        ar: true, // Enable AR Quick Look on iOS
        autoRotate: true,
        cameraControls: true,
        // You might need to adjust background color depending on model
        backgroundColor: Colors.white,
        // Optional: Add error handling
        loading: Loading.eager,
        // Optional: Specify camera settings
        // cameraOrbit: '0deg 75deg 1.5m',
        // cameraTarget: '0m 0m 0m',
      ),
    );
  }
}
