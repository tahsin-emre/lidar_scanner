// ignore_for_file: avoid_dynamic_calls, document_ignores

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:lidar_scanner/product/model/export_format.dart';
import 'package:lidar_scanner/product/model/export_result.dart';
import 'package:lidar_scanner/product/model/scan_result.dart';
import 'package:lidar_scanner/product/utils/enum/scan_quality.dart';

@singleton
final class ScannerService {
  ScannerService();

  static const _channel = MethodChannel('com.example.lidarScanner');

  Future<bool> checkTalent() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkTalent');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> startScanning({required ScanQuality quality}) async {
    try {
      await _channel.invokeMethod('startScanning', {
        'scanQuality': quality.name,
        'scanType': 'roomScan',
        'configuration': {
          ...quality.configuration,
        },
      });
    } on PlatformException {
      rethrow;
    }
  }

  Future<void> stopScanning() async {
    try {
      await _channel.invokeMethod('stopScanning');
    } on PlatformException {
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
                  .map(
                    (e) => ScanArea(
                      x: e['x'] as double? ?? 0.0,
                      y: e['y'] as double? ?? 0.0,
                      width: e['width'] as double? ?? 0.0,
                      height: e['height'] as double? ?? 0.0,
                    ),
                  )
                  .toList()
              : [],
        );
      }
      return const ScanResult(
        progress: 0,
        isComplete: false,
        missingAreas: [],
      );
    } on PlatformException {
      return const ScanResult(
        progress: 0,
        isComplete: false,
        missingAreas: [],
      );
    }
  }

  Future<ExportResult> exportModel({
    required ExportFormat format,
    required String fileName,
  }) async {
    try {
      final path = await _channel.invokeMethod<String>('exportModel', {
        'format': format.name,
        'fileName': fileName,
      });

      return ExportResult(
        filePath: path ?? '',
        isSuccess: path != null && path.isNotEmpty,
      );
    } on PlatformException {
      return const ExportResult(filePath: '', isSuccess: false);
    }
  }
}
