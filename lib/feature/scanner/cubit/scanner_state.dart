import 'package:equatable/equatable.dart';
import 'package:lidar_scanner/product/model/scan_result.dart';

class ScannerState extends Equatable {
  const ScannerState({
    this.canScan = false,
    this.isScanning = false,
    this.scanProgress = 0.0,
    this.isComplete = false,
    this.missingAreas = const [],
  });

  ScannerState copyWith({
    bool? canScan,
    bool? isScanning,
    double? scanProgress,
    bool? isComplete,
    List<ScanArea>? missingAreas,
  }) {
    return ScannerState(
      canScan: canScan ?? this.canScan,
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress ?? this.scanProgress,
      isComplete: isComplete ?? this.isComplete,
      missingAreas: missingAreas ?? this.missingAreas,
    );
  }

  final bool canScan;
  final bool isScanning;
  final double scanProgress;
  final bool isComplete;
  final List<ScanArea> missingAreas;

  @override
  List<Object?> get props =>
      [canScan, isScanning, scanProgress, isComplete, missingAreas];
}
