import 'package:freezed_annotation/freezed_annotation.dart';

part 'scan_result.freezed.dart';

@freezed
class ScanResult with _$ScanResult {
  const factory ScanResult({
    required double progress,
    required bool isComplete,
    required List<ScanArea> missingAreas,
  }) = _ScanResult;
}

@freezed
class ScanArea with _$ScanArea {
  const factory ScanArea({
    required double x,
    required double y,
    required double width,
    required double height,
  }) = _ScanArea;
}
