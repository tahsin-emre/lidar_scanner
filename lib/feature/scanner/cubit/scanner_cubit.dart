import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_state.dart';
import 'package:lidar_scanner/product/model/export_format.dart';
import 'package:lidar_scanner/product/model/export_result.dart';
import 'package:lidar_scanner/product/service/scanner_service.dart';
import 'package:lidar_scanner/product/utils/enum/scan_quality.dart';
import 'package:lidar_scanner/product/utils/enum/scan_type.dart';

@injectable
final class ScannerCubit extends Cubit<ScannerState> {
  ScannerCubit(this._service) : super(const ScannerState());

  final ScannerService _service;
  ScanType _currentScanType = ScanType.roomScan;

  Future<void> checkTalent() async {
    final supported = await _service.checkTalent();
    emit(state.copyWith(canScan: supported));
  }

  Future<void> startScanning({
    required ScanQuality scanQuality,
    ScanType scanType = ScanType.roomScan,
  }) async {
    _currentScanType = scanType;
    await _service.startScanning(quality: scanQuality, scanType: scanType);
    emit(state.copyWith(isScanning: true));
    await _monitorScanningProgress();
  }

  Future<void> stopScanning() async {
    emit(state.copyWith(isScanning: false));
    await _service.stopScanning();
  }

  Future<void> _monitorScanningProgress() async {
    while (state.isScanning) {
      await getScanProgress();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> getScanProgress() async {
    final progress = await _service.getScanProgress();
    emit(state.copyWith(
      scanProgress: progress.progress,
      isComplete: progress.isComplete,
      missingAreas: progress.missingAreas,
    ));
  }

  Future<ExportResult> exportModel({
    required ExportFormat format,
    required String fileName,
  }) async {
    return _service.exportModel(format: format, fileName: fileName);
  }

  Future<void> setObjectScanCenter() async {
    if (_currentScanType == ScanType.objectScan) {
      await _service.setObjectScanCenter();
    }
  }

  // --- Entertainment Mode Cubit Methods ---
  Future<void> toggleEntertainmentMode() async {
    if (state.isEntertainmentModeActive) {
      await _service.stopEntertainmentMode();
      emit(state.copyWith(isEntertainmentModeActive: false));
    } else {
      // Ensure regular scanning is stopped before starting entertainment mode
      if (state.isScanning) {
        await stopScanning();
      }
      await _service.startEntertainmentMode();
      emit(state.copyWith(isEntertainmentModeActive: true));
    }
  }

  // New method to save scan data for entertainment mode
  Future<bool> saveScanData() async {
    // Make sure we're not scanning
    if (state.isScanning) {
      await stopScanning();
    }

    // Try to save the scan data
    final success = await _service.saveScanData();
    return success;
  }

  // Improved method to start entertainment mode with scan data
  Future<void> startEntertainmentModeWithSavedScan() async {
    // Make sure we're not scanning
    if (state.isScanning) {
      await stopScanning();
    }

    // First save the current scan data
    final scanSaved = await saveScanData();
    if (!scanSaved) {
      print('Warning: Failed to save scan data for entertainment mode');
    }

    // Then start entertainment mode
    await _service.startEntertainmentMode();
    emit(state.copyWith(isEntertainmentModeActive: true));

    // Automatically start coin spawning when entertainment mode is activated
    if (state.isEntertainmentModeActive) {
      await spawnEntertainmentObject(
          assetName: 'coin',
          properties: {'continuous': true} // Enable continuous coin spawning
          );
    }
  }

  Future<void> spawnEntertainmentObject({
    required String assetName,
    Map<String, dynamic>? properties,
  }) async {
    if (state.isEntertainmentModeActive) {
      await _service.spawnObjectInEntertainmentMode(
        assetName: assetName,
        properties: properties,
      );
    } else {
      // Optionally, log a warning or inform the user that entertainment mode is not active
      print('Entertainment mode is not active. Cannot spawn object.');
    }
  }
  // --- End Entertainment Mode Cubit Methods ---
}
