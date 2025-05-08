import 'package:equatable/equatable.dart';

class ExportResult extends Equatable {
  const ExportResult({
    required this.filePath,
    required this.isSuccess,
  });

  final String filePath;
  final bool isSuccess;

  @override
  List<Object?> get props => [filePath, isSuccess];
}
