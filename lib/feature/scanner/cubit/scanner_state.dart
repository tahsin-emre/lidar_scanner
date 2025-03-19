import 'package:equatable/equatable.dart';

final class ScannerState extends Equatable {
  const ScannerState({required this.canScan});

  ScannerState copyWith({bool? canScan}) =>
      ScannerState(canScan: canScan ?? this.canScan);

  final bool canScan;

  @override
  List<Object?> get props => [canScan];
}
