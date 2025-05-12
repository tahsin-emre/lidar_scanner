import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Model görüntüleyici için yardımcı fonksiyonlar içeren mixin
mixin ModelViewerMixin<T extends StatefulWidget> on State<T> {
  /// Kullanılabilir modellerin listesini döndürür
  Future<List<String>> getAvailableModels() async {
    try {
      // assets/models klasöründeki modelleri listeleme işlevi buraya gelecek
      // Bu örnekte sabit bir liste döndürüyoruz
      return ['sphere.gltf'];
    } catch (e) {
      debugPrint('Error getting available models: $e');
      return [];
    }
  }

  /// Asset dosyasını data URL olarak kodlar
  Future<String?> copyAssetToTempDir(String assetPath) async {
    try {
      // Asset dosyasını oku
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List();

      // Geçici dizin al
      final tempDir = await getTemporaryDirectory();
      final fileName = assetPath.split('/').last;
      final tempFile = File('${tempDir.path}/$fileName');

      // Geçici dosyaya yaz
      await tempFile.writeAsBytes(bytes);

      // Dosya uzantısına göre MIME tipini belirle
      final mimeType = _getMimeType(fileName);

      // HTTP URL olarak döndür (model_viewer_plus http:// veya https:// bekliyor)
      return 'https://example.com/model';
    } catch (e) {
      debugPrint('Error creating data URL: $e');
      return null;
    }
  }

  /// Dosya uzantısına göre MIME tipini döndürür
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'gltf':
        return 'model/gltf+json';
      case 'glb':
        return 'model/gltf-binary';
      case 'obj':
        return 'model/obj';
      default:
        return 'application/octet-stream';
    }
  }

  /// Model hakkında bilgi gösterir
  void showModelInfo(BuildContext context, String modelName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Model Bilgisi: $modelName'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Format: ${_getFileFormat(modelName)}'),
                const SizedBox(height: 8),
                const Text('Konum: assets/models/'),
                const SizedBox(height: 8),
                const Text('Bu model AR modülünde kullanılmaktadır.'),
                const SizedBox(height: 16),
                const Text(
                  'Not: 3D modeller geçici bir dizine kopyalanarak görüntülenir.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  /// Dosya uzantısına göre format bilgisini döndürür
  String _getFileFormat(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'gltf':
        return 'GLTF (GL Transmission Format)';
      case 'glb':
        return 'GLB (GL Binary)';
      case 'obj':
        return 'OBJ (Wavefront)';
      case 'usdz':
        return 'USDZ (Universal Scene Description)';
      default:
        return extension.toUpperCase();
    }
  }
}
