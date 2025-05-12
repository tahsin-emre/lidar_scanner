import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:lidar_scanner/product/model/export_format.dart';
import 'package:lidar_scanner/product/model/export_result.dart';
import 'package:lidar_scanner/product/model/scan_result.dart';
import 'package:lidar_scanner/product/utils/enum/scan_quality.dart';
import 'package:lidar_scanner/product/utils/enum/scan_type.dart';

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

  Future<void> startScanning(
      {required ScanQuality quality, required ScanType scanType}) async {
    try {
      await _channel.invokeMethod('startScanning', {
        'scanQuality': quality.name,
        'scanType': scanType.name,
        'configuration': {
          ...quality.configuration,
          ...scanType.configuration,
        },
      });
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
          await _channel.invokeMapMethod<String, dynamic>('getScanProgress');
      if (result != null) {
        return ScanResult(
          progress: result['progress'] as double? ?? 0.0,
          isComplete: result['isComplete'] as bool? ?? false,
          missingAreas: result['missingAreas'] != null
              ? (result['missingAreas'] as List)
                  .map((e) => ScanArea(
                        x: e['x'] as double? ?? 0.0,
                        y: e['y'] as double? ?? 0.0,
                        width: e['width'] as double? ?? 0.0,
                        height: e['height'] as double? ?? 0.0,
                      ))
                  .toList()
              : [],
        );
      }
      return const ScanResult(
          progress: 0.0, isComplete: false, missingAreas: []);
    } on PlatformException catch (e) {
      print('Error getting scan progress: ${e.message}');
      return const ScanResult(
          progress: 0.0, isComplete: false, missingAreas: []);
    }
  }

  Future<ExportResult> exportModel(
      {required ExportFormat format, required String fileName}) async {
    try {
      final path = await _channel.invokeMethod<String>('exportModel', {
        'format': format.name,
        'fileName': fileName,
      });

      return ExportResult(
          filePath: path ?? '', isSuccess: path != null && path.isNotEmpty);
    } on PlatformException catch (e) {
      print('Error exporting model: ${e.message}');
      return const ExportResult(filePath: '', isSuccess: false);
    }
  }

  Future<void> setObjectScanCenter() async {
    try {
      await _channel.invokeMethod('setObjectScanCenter');
    } on PlatformException catch (e) {
      print('Error setting object scan center: ${e.message}');
      rethrow;
    }
  }

  // New method to save current scan data for entertainment mode
  Future<bool> saveScanData() async {
    try {
      final result = await _channel.invokeMethod<bool>('saveScanData');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error saving scan data: ${e.message}');
      return false;
    }
  }

  // --- New Entertainment Mode Methods ---
  Future<void> startEntertainmentMode() async {
    try {
      await _channel.invokeMethod('startEntertainmentMode');
    } on PlatformException catch (e) {
      print('Error starting entertainment mode: ${e.message}');
      // Consider how to handle this error, maybe rethrow or return a status
    }
  }

  Future<void> stopEntertainmentMode() async {
    try {
      await _channel.invokeMethod('stopEntertainmentMode');
    } on PlatformException catch (e) {
      print('Error stopping entertainment mode: ${e.message}');
    }
  }

  Future<void> spawnObjectInEntertainmentMode(
      {required String assetName, Map<String, dynamic>? properties}) async {
    try {
      // Add a flag for continuous spawning
      final Map<String, dynamic> updatedProperties = properties ?? {};
      if (properties?.containsKey('continuous') != true) {
        updatedProperties['continuous'] = true; // Always use continuous mode
      }

      await _channel.invokeMethod('spawnObjectInEntertainmentMode', {
        'assetName': assetName,
        'properties': updatedProperties,
      });
    } on PlatformException catch (e) {
      print('Error spawning object in entertainment mode: ${e.message}');
    }
  }
  // --- End New Entertainment Mode Methods ---
}
