import 'package:injectable/injectable.dart';

@singleton
final class ScannerService {
  ScannerService();

  Future<bool> checkTalent() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return false;
  }
}
