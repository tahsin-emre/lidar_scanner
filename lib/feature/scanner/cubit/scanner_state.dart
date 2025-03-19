import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lidar_scanner/product/model/scan_result.dart';

part 'scanner_state.freezed.dart';

@freezed
class ScannerState with _$ScannerState {
  const factory ScannerState({
    required bool canScan,
    required bool isScanning,
    @Default(0.0) double scanProgress,
    @Default(false) bool isComplete,
    @Default([]) List<ScanArea> missingAreas,
  }) = _ScannerState;
}
