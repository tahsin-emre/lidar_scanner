import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:lidar_scanner/feature/ar_physics/cubit/ar_physics_cubit.dart';
import 'package:lidar_scanner/feature/ar_physics/service/ar_physics_service.dart';
import 'package:lidar_scanner/feature/interactive_physics/cubit/interactive_physics_cubit.dart';
import 'package:lidar_scanner/product/di/locator.config.dart';
import 'package:lidar_scanner/product/service/physics_service.dart';

final locator = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: true, // default
  usesNullSafety: true, // required for null safety
)
Future<void> configureDependencies() async {
  locator.init();

  // Manually register physics service and cubit to ensure they're available
  if (!locator.isRegistered<PhysicsService>()) {
    locator.registerSingleton<PhysicsService>(PhysicsService());
  }

  if (!locator.isRegistered<InteractivePhysicsCubit>()) {
    locator.registerFactory<InteractivePhysicsCubit>(
      () => InteractivePhysicsCubit(locator<PhysicsService>()),
    );
  }

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
