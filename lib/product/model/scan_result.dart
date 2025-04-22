import 'package:equatable/equatable.dart';

class ScanResult extends Equatable {
  const ScanResult({
    required this.progress,
    required this.isComplete,
    required this.missingAreas,
  });

  final double progress;
  final bool isComplete;
  final List<ScanArea> missingAreas;

  ScanResult copyWith({
    double? progress,
    bool? isComplete,
    List<ScanArea>? missingAreas,
  }) {
    return ScanResult(
      progress: progress ?? this.progress,
      isComplete: isComplete ?? this.isComplete,
      missingAreas: missingAreas ?? this.missingAreas,
    );
  }

  @override
  List<Object?> get props => [progress, isComplete, missingAreas];
}

class ScanArea extends Equatable {
  const ScanArea({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
  final double x;
  final double y;
  final double width;
  final double height;

  ScanArea copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return ScanArea(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  List<Object?> get props => [x, y, width, height];
}
