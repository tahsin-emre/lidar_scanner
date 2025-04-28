enum ScanQuality {
  lowQuality, // Düşük kalite - hızlı tarama
  highQuality, // Yüksek kalite - detaylı tarama
}

extension ScanQualityExtension on ScanQuality {
  String get name => toString().split('.').last;

  Map<String, dynamic> get configuration {
    switch (this) {
      case ScanQuality.lowQuality:
        return {
          'resolution': 0.03,
          'maxPoints': 30000,
          'quality': 'low',
          'updateInterval': 0.08,
          'smoothingFactor': 0.5,
          'enhanceVisuals': true,
          'wireframe': true,
          'wireThickness': 1.0,
        };
      case ScanQuality.highQuality:
        return {
          'resolution': 0.005,
          'maxPoints': 300000,
          'quality': 'high',
          'updateInterval': 0.03,
          'smoothingFactor': 0.8,
          'enhanceVisuals': true,
          'enhancedColors': true,
          'textureResolution': 'high',
          'wireframe': true,
          'wireThickness': 0.5,
          'detailedBackground': true,
        };
    }
  }
}
