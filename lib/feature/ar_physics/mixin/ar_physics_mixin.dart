import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lidar_scanner/feature/ar_physics/cubit/ar_physics_cubit.dart';

/// AR Fizik ekranı için gerekli state yönetimini sağlayan mixin
mixin ARPhysicsMixin<T extends StatefulWidget> on State<T> {
  /// AR Fizik Cubit örneği
  final arPhysicsCubit = GetIt.I<ARPhysicsCubit>();

  @override
  void dispose() {
    super.dispose();
  }
}
