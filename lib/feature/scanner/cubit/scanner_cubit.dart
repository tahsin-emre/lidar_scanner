import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_state.dart';
import 'package:lidar_scanner/product/model/export_format.dart';
import 'package:lidar_scanner/product/model/export_result.dart';
import 'package:lidar_scanner/product/service/scanner_service.dart';
import 'package:lidar_scanner/product/utils/enum/scan_quality.dart';

@injectable
final class ScannerCubit extends Cubit<ScannerState> {
  ScannerCubit(this._service) : super(const ScannerState());

  final ScannerService _service;

  Future<void> checkTalent() async {
    final supported = await _service.checkTalent();
    emit(state.copyWith(canScan: supported));
  }

  Future<void> startScanning({
    required ScanQuality scanQuality,
  }) async {
    await _service.startScanning(quality: scanQuality);
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
}
