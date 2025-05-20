import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lidar_scanner/feature/ar_physics/cubit/ar_physics_cubit.dart';

mixin ARPhysicsMixin<T extends StatefulWidget> on State<T> {
  final arPhysicsCubit = GetIt.I<ARPhysicsCubit>();

  @override
  void initState() {
    super.initState();
    arPhysicsCubit.initialize();
  }

  @override
  void dispose() {
    arPhysicsCubit.close();
    super.dispose();
  }
}
