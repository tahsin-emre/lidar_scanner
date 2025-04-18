import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ModelViewerView extends StatelessWidget {
  const ModelViewerView({
    required this.modelPath,
    required this.file,
    super.key,
  });
  final FileSystemEntity file;
  final String modelPath;

  @override
  Widget build(BuildContext context) {
    // Extract filename for the AppBar title
    final fileName = modelPath.split('/').last;
    final file = File(modelPath);
    print(file);
    return Scaffold(
      appBar: AppBar(title: Text(fileName)),
      body: Flutter3DViewer.obj(
        src: file.path,

        onProgress: (double progressValue) {
          debugPrint('model loading progress : $progressValue');
        },
        //This callBack will call after model loaded successfully and will return model address
        onLoad: (String modelAddress) {
          debugPrint('model loaded : $modelAddress');
        },
        //this callBack will call when model failed to load and will return failure erro
        onError: (String error) {
          debugPrint('model failed to load : $error');
        },
      ),
    );
  }
}



  // body: ModelViewer(
  //       src: 'file://$modelPath', // Important: Use the file:// scheme

  //     ),