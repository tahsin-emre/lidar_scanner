import 'package:flutter/material.dart';
import 'package:lidar_scanner/feature/ar_physics/cubit/ar_physics_cubit.dart';
import 'package:lidar_scanner/product/di/locator.dart';

mixin ArPhysicsMixin<T extends StatefulWidget> on State<T> {
  late final ArPhysicsCubit arPhysicsCubit;

  @override
  void initState() {
    super.initState();
    arPhysicsCubit = locator<ArPhysicsCubit>();
  }

  @override
  void dispose() {
    arPhysicsCubit.close();
    super.dispose();
  }
}
