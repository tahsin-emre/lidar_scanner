import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:lidar_scanner/product/model/export_format.dart';
import 'package:lidar_scanner/product/model/scan_result.dart';

@singleton
final class ScannerService {
  ScannerService();

  static const _channel = MethodChannel('com.example.lidarScanner');

  Future<bool> checkTalent() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkTalent');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error checking LiDAR support: ${e.message}');
      return false;
    }
  }

  Future<void> startScanning() async {
    try {
      await _channel.invokeMethod('startScanning');
    } on PlatformException catch (e) {
      print('Error starting scan: ${e.message}');
      rethrow;
    }
  }

  Future<void> stopScanning() async {
    try {
      await _channel.invokeMethod('stopScanning');
    } on PlatformException catch (e) {
      print('Error stopping scan: ${e.message}');
      rethrow;
    }
  }

  Future<ScanResult> getScanProgress() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getScanProgress');
      if (result == null) {
        throw PlatformException(
          code: 'INVALID_RESULT',
          message: 'Failed to get scan progress',
        );
      }

      return ScanResult(
        progress: result['progress'] as double,
        isComplete: result['isComplete'] as bool,
        missingAreas: (result['missingAreas'] as List)
            .map((area) => ScanArea(
                  x: area['x'] as double,
                  y: area['y'] as double,
                  width: area['width'] as double,
                  height: area['height'] as double,
                ))
            .toList(),
      );
    } on PlatformException catch (e) {
      print('Error getting scan progress: ${e.message}');
      rethrow;
    }
  }

  Future<String> exportModel(ExportFormat format, String fileName) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'exportModel',
        {'format': format.name, 'fileName': fileName},
      );
      return result ?? '';
    } on PlatformException catch (e) {
      print('Error exporting model: ${e.message}');
      rethrow;
    }
  }
}
