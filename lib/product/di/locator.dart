import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:lidar_scanner/feature/ar_physics/cubit/ar_physics_cubit.dart';
import 'package:lidar_scanner/product/di/locator.config.dart';
import 'package:lidar_scanner/product/service/ar_physics_service.dart';

final locator = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: true, // default
  usesNullSafety: true, // required for null safety
)
Future<void> configureDependencies() async {
  locator.init();

  // Register AR Physics Service and Cubit
  if (!locator.isRegistered<ARPhysicsService>()) {
    locator.registerSingleton<ARPhysicsService>(ARPhysicsService());
  }

  if (!locator.isRegistered<ARPhysicsCubit>()) {
    locator.registerFactory<ARPhysicsCubit>(
      () => ARPhysicsCubit(locator<ARPhysicsService>()),
    );
  }
}
