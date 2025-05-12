enum ScanType {
  roomScan, // Tüm odayı tarama
}

extension ScanTypeExtension on ScanType {
  String get name => toString().split('.').last;

  Map<String, dynamic> get configuration {
    switch (this) {
      case ScanType.roomScan:
        return {
          'focusMode': false,
          'objectIsolation': false,
          'backgroundRemoval': false,
          'maxDistance': 10.0, // Oda tarama için maksimum mesafe (metre)
          'autoCenter': false,
          'targetObjectDetection': false,
        };
    }
  }
}
