import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lidar_scanner/feature/ar_physics/cubit/ar_physics_state.dart';
import 'package:lidar_scanner/product/model/physics_object.dart';
import 'package:lidar_scanner/product/service/ar_physics_service.dart';

@injectable
class ARPhysicsCubit extends Cubit<ARPhysicsState> {
  ARPhysicsCubit(this._arPhysicsService) : super(const ARPhysicsState());

  final ARPhysicsService _arPhysicsService;
  final math.Random _random = math.Random();

  Timer? _fpsUpdateTimer;
  int _arViewId = -1;

  Future<void> initialize() async {
    emit(state.copyWith(isInitialized: false, error: ''));
    _fpsUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateFps(),
    );
  }

  void setARViewId(int id) {
    _arViewId = id;
    _arPhysicsService
      ..setViewId(id)
      ..clearObjects();
    emit(state.copyWith(isInitialized: true));
  }

  Future<void> placeObjectAtScreenPosition(double x, double y) async {
    if (!_isARViewValid()) {
      emit(state.copyWith(error: 'AR View not initialized. Please try again.'));
      return;
    }

    try {
      final worldPosition = await _arPhysicsService.screenToWorldPosition(x, y);
      if (worldPosition == null) {
        _addObjectAtPosition([0, 0, -0.5]);
        return;
      }
      _addObjectAtPosition(worldPosition);
    } on Exception {
      _addObjectAtPosition([0, 0, -0.5]);
    }
  }

  void _addObjectAtPosition(List<double> position) {
    final color = Color.fromRGBO(
      _random.nextInt(200) + 55,
      _random.nextInt(200) + 55,
      _random.nextInt(200) + 55,
      1,
    );
    final dateInMillis = DateTime.now().millisecondsSinceEpoch;

    final newObject = PhysicsObject(
      id: 'obj_${dateInMillis}_${_random.nextInt(10000)}',
      type: state.selectedObjectType,
      position: position,
      rotation: const [0, 0, 0, 1],
      scale: const [1, 1, 1],
      velocity: const [0, 0, 0],
      angularVelocity: const [0, 0, 0],
      mass: 1,
      color: color,
    );

    _arPhysicsService.addPhysicsObject(newObject).then((success) {
      if (success) {
        final updatedObjects = List<PhysicsObject>.from(state.objects)
          ..add(newObject);
        emit(state.copyWith(objects: updatedObjects));
      }
    });
  }

  Future<void> clearAllObjects() async {
    if (!_isARViewValid()) return;

    await _arPhysicsService.clearObjects();
    emit(state.copyWith(objects: const []));
  }

  void selectObjectType(PhysicsObjectType type) {
    if (state.selectedObjectType != type) {
      emit(state.copyWith(selectedObjectType: type));
    }
  }

  Future<void> _updateFps() async {
    if (!_isARViewValid()) return;
    final fps = await _arPhysicsService.getFps();
    if (fps > 0) {
      emit(state.copyWith(fps: fps));
    }
  }

  @override
  Future<void> close() async {
    _fpsUpdateTimer?.cancel();
    _fpsUpdateTimer = null;

    await super.close();
  }

  bool _isARViewValid() {
    return _arViewId >= 0;
  }
}
