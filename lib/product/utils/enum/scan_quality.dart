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
          'resolution': 0.001, // 1mm ultra-yüksek çözünürlük
          'maxPoints': 1000000, // Çok daha fazla nokta
          'quality': 'ultra',
          'updateInterval': 0.01, // 10ms - çok hızlı güncelleme
          'smoothingFactor': 0.3, // Daha az yumuşatma - köşeler daha net
          'enhanceVisuals': true,
          'enhancedColors': true,
          'textureResolution': 'ultra', // En yüksek doku çözünürlüğü
          'wireframe': true,
          'wireThickness': 0.5,
          'detailedBackground': true,
          'edgeDetection': true, // Köşe algılama
          'precisionMode': true, // Hassas mod
          'maxDetail': true, // Maksimum detay
          'exportQuality': 'raw', // İşlenmemiş ham veri kalitesi
          'captureMeshDensity': 'extreme', // Aşırı yoğun mesh
        };
    }
  }
}
