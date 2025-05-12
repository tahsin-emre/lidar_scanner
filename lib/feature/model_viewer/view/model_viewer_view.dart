import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lidar_scanner/feature/model_viewer/mixin/model_viewer_mixin.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';

class ModelViewerView extends StatefulWidget {
  const ModelViewerView({super.key});

  @override
  State<ModelViewerView> createState() => _ModelViewerViewState();
}

class _ModelViewerViewState extends State<ModelViewerView>
    with ModelViewerMixin {
  String _selectedModel = 'sphere.gltf';
  bool _isLoading = false;
  String? _errorMessage;
  String? _modelUrl;

  final List<String> _availableModels = [
    'sphere.gltf',
    // Diğer modeller buraya eklenebilir
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailableModels();
    _prepareModelFile(_selectedModel);
  }

  Future<void> _loadAvailableModels() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final models = await getAvailableModels();
      setState(() {
        if (models.isNotEmpty) {
          _availableModels.clear();
          _availableModels.addAll(models);
          _selectedModel = models.first;
          _prepareModelFile(_selectedModel);
        }
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Modeller yüklenemedi: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Asset dosyasını geçici bir dosyaya kopyalar ve URL'ini döndürür
  Future<void> _prepareModelFile(String modelName) async {
    setState(() {
      _isLoading = true;
      _modelUrl = null;
    });

    try {
      final url = await copyAssetToTempDir('assets/models/$modelName');

      setState(() {
        _modelUrl = url;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Model dosyası hazırlanamadı: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Model Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableModels,
            tooltip: 'Modelleri Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Model seçici
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: _selectedModel,
              isExpanded: true,
              hint: const Text('Model Seç'),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedModel = newValue;
                    _errorMessage = null;
                    _prepareModelFile(newValue);
                  });
                }
              },
              items: _availableModels
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),

          // Hata mesajı
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // Yükleme göstergesi
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Model görüntüleyici
          Expanded(
            child: _modelUrl != null
                ? ModelViewer(
                    backgroundColor: const Color.fromARGB(255, 30, 30, 30),
                    src: 'assets/models/sphere.gltf'!,
                    alt: '3D Model',
                    ar: false,
                    autoRotate: true,
                    cameraControls: true,
                  )
                : const Center(
                    child: Text('Model yükleniyor...'),
                  ),
          ),
        ],
      ),
      // Model hakkında bilgi gösterme butonu
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModelInfo(context, _selectedModel);
        },
        child: const Icon(Icons.info),
      ),
    );
  }
}
