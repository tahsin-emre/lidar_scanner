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
  }

  Future<void> stopScanning() async {
    emit(state.copyWith(isScanning: false));
    await _service.stopScanning();
  }

  Future<ExportResult> exportModel({
    required ExportFormat format,
    required String fileName,
  }) async {
    return _service.exportModel(format: format, fileName: fileName);
  }
}
