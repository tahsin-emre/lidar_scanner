import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lidar_scanner/feature/scanner/cubit/scanner_state.dart';
import 'package:lidar_scanner/product/service/scanner_service.dart';

@injectable
final class ScannerCubit extends Cubit<ScannerState> {
  ScannerCubit(this._scannerService)
    : super(const ScannerState(canScan: false));

  final ScannerService _scannerService;

  Future<void> checkTalent() async {
    final result = await _scannerService.checkTalent();
    emit(state.copyWith(canScan: result));
  }
}
