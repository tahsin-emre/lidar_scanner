import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_state.dart';
import 'package:lidar_scanner/product/model/export_format.dart';
import 'package:lidar_scanner/product/service/scanner_service.dart';

@injectable
final class ScannerCubit extends Cubit<ScannerState> {
  ScannerCubit(this._scannerService)
      : super(const ScannerState(canScan: false, isScanning: false));

  final ScannerService _scannerService;

  Future<void> checkTalent() async {
    final result = await _scannerService.checkTalent();
    emit(state.copyWith(canScan: result));
  }

  Future<void> startScanning() async {
    emit(state.copyWith(isScanning: true));
    await _scannerService.startScanning();
    await _monitorScanningProgress();
  }

  Future<void> stopScanning() async {
    emit(state.copyWith(isScanning: false));
    await _scannerService.stopScanning();
  }

  Future<void> _monitorScanningProgress() async {
    while (state.isScanning) {
      final progress = await _scannerService.getScanProgress();
      emit(
        state.copyWith(
          scanProgress: progress.progress,
          isComplete: progress.isComplete,
          missingAreas: progress.missingAreas,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<String> exportModel(ExportFormat format, String fileName) async {
    return _scannerService.exportModel(format, fileName);
  }
}
