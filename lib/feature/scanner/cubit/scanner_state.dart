import 'package:equatable/equatable.dart';
import 'package:lidar_scanner/product/model/scan_result.dart';

class ScannerState extends Equatable {
  const ScannerState({
    this.canScan = false,
    this.isScanning = false,
    this.scanProgress = 0.0,
    this.isComplete = false,
    this.missingAreas = const [],
    this.isEntertainmentModeActive = false,
  });

  ScannerState copyWith({
    bool? canScan,
    bool? isScanning,
    double? scanProgress,
    bool? isComplete,
    List<ScanArea>? missingAreas,
    bool? isEntertainmentModeActive,
  }) {
    return ScannerState(
      canScan: canScan ?? this.canScan,
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress ?? this.scanProgress,
      isComplete: isComplete ?? this.isComplete,
      missingAreas: missingAreas ?? this.missingAreas,
      isEntertainmentModeActive:
          isEntertainmentModeActive ?? this.isEntertainmentModeActive,
    );
  }

  final bool canScan;
  final bool isScanning;
  final double scanProgress;
  final bool isComplete;
  final List<ScanArea> missingAreas;
  final bool isEntertainmentModeActive;

  @override
  List<Object?> get props => [
        canScan,
        isScanning,
        scanProgress,
        isComplete,
        missingAreas,
        isEntertainmentModeActive
      ];
}
