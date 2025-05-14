import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lidar_scanner/feature/interactive_physics/cubit/interactive_physics_cubit.dart';

/// Mixin for the interactive physics view
mixin InteractivePhysicsMixin<T extends StatefulWidget> on State<T> {
  /// The physics cubit for managing the physics simulation
  late final InteractivePhysicsCubit physicsCubit;

  @override
  void initState() {
    super.initState();
    physicsCubit = GetIt.instance.get<InteractivePhysicsCubit>();
  }

  @override
  void dispose() {
    // No need to dispose the cubit here as it's managed by GetIt
    super.dispose();
  }
}
