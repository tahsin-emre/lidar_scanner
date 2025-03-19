import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:lidar_scanner/product/di/locator.config.dart';

final locator = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: true, // default
  usesNullSafety: true, // required for null safety
)
Future<void> configureDependencies() async {
  locator.init();
}
