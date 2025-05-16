import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lidar_scanner/feature/interactive_physics/cubit/interactive_physics_state.dart';
import 'package:lidar_scanner/product/model/physics_object.dart';
import 'package:lidar_scanner/product/service/physics_service.dart';

/// Cubit for managing the interactive physics simulation
@injectable
class InteractivePhysicsCubit extends Cubit<InteractivePhysicsState> {
  /// Create a new interactive physics cubit
  InteractivePhysicsCubit(this._physicsService)
      : super(const InteractivePhysicsState());

  final PhysicsService _physicsService;
  Timer? _fpsUpdateTimer;
  Timer? _objectRainTimer;
  int _arViewId = -1;
  final _random = math.Random();

  /// Initialize the physics environment with scan data
  Future<void> initializePhysics({required String scanPath}) async {
    emit(state.copyWith(
      isLoading: true,
      error: null,
      isAlignmentComplete: false,
      modelOffsetX: 0.0,
      modelOffsetY: 0.0,
    ));

    try {
      // Only initialize physics if ARView has been created
      if (_arViewId >= 0) {
        await _physicsService.initializePhysics(scanPath: scanPath);

        // Start FPS update timer
        _fpsUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          _updateFps();
        });

        emit(state.copyWith(
          isLoading: false,
          isSimulationRunning: true,
        ));
      } else {
        print('ARView not initialized yet. Waiting for view creation...');
        emit(state.copyWith(
          isLoading: false,
          error: 'AR View not initialized. Please try again.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to initialize physics: $e',
      ));
    }
  }

  /// Set the AR view ID for platform view communication
  void setARViewId(int id) {
    print('InteractivePhysicsCubit: Setting ARViewId to $id');
    _arViewId = id;
    _physicsService.setViewId(id);

    // If we were waiting for view to be created, try initializing again
    if (state.error == 'AR View not initialized. Please try again.' &&
        !state.isLoading) {
      emit(state.copyWith(error: null));
    }
  }

  /// Adjust the position of the AR model by the given deltas.
  Future<void> adjustModelPosition(double deltaX, double deltaY) async {
    if (!_isARViewValid() || !state.isSimulationRunning) return;

    try {
      final success = await _physicsService.adjustModelPosition(deltaX, deltaY);
      if (success) {
        print('InteractivePhysicsCubit: Model position adjusted successfully.');
      } else {
        print(
            'InteractivePhysicsCubit: Failed to adjust model position via service.');
      }
    } catch (e) {
      print('InteractivePhysicsCubit: Error adjusting model position: $e');
    }
  }

  /// Rotate the model around its Y axis
  Future<void> rotateModelY(double angle) async {
    if (_arViewId < 0 || !state.isSimulationRunning) {
      print(
          'Cannot rotate model: ARViewId = $_arViewId, isSimulationRunning = ${state.isSimulationRunning}');
      return;
    }

    try {
      // Update the model rotation in the native code
      final success = await _physicsService.rotateModelY(angle);

      if (success) {
        print('Model rotated by angle: $angle');
      } else {
        print('Failed to rotate model');
      }
    } catch (e) {
      debugPrint('Error rotating model: $e');
    }
  }

  /// Zoom in/out on the model - scale factor is relative (1.0 is no change)
  Future<void> zoomModel(double scaleFactor) async {
    if (_arViewId < 0 || !state.isSimulationRunning) {
      print(
          'Cannot zoom model: ARViewId = $_arViewId, isSimulationRunning = ${state.isSimulationRunning}');
      return;
    }

    try {
      // Update the model zoom in the native code
      final success = await _physicsService.zoomModel(scaleFactor);

      if (success) {
        print('Model zoomed by factor: $scaleFactor');
      } else {
        print('Failed to zoom model');
      }
    } catch (e) {
      debugPrint('Error zooming model: $e');
    }
  }

  /// Reset the model alignment to initial position
  Future<void> resetAlignment() async {
    if (!_isARViewValid() || !state.isSimulationRunning) return;

    try {
      // Call the new service method to reset position and rotation to origin
      final success = await _physicsService.resetModelPositionToOrigin();

      if (success) {
        // Optionally, if you were tracking offsets in Flutter state for some reason,
        // you might want to reset them here too, though it seems less relevant now.
        // emit(state.copyWith(modelOffsetX: 0.0, modelOffsetY: 0.0));
        print(
            'InteractivePhysicsCubit: Model position and rotation reset to origin successfully.');
      } else {
        print(
            'InteractivePhysicsCubit: Failed to reset model position to origin via service.');
      }
    } catch (e) {
      print(
          'InteractivePhysicsCubit: Error resetting model position to origin: $e');
    }
  }

  /// Complete the alignment phase and start using the physics simulation
  void completeAlignment() async {
    if (state.isAlignmentComplete) return; // Avoid running if already complete

    emit(state.copyWith(isAlignmentComplete: true));
    print(
        'InteractivePhysicsCubit: Alignment completed. Ready for physics interaction.');

    // Give a moment for the physics to stabilize before hiding mesh
    await Future.delayed(const Duration(milliseconds: 500));

    bool meshHiddenSuccessfully = false;
    try {
      print(
          'InteractivePhysicsCubit: Setting mesh to invisible to enable occlusion');
      bool success = await _physicsService.setMeshVisibility(false);
      if (!success) {
        print(
            'InteractivePhysicsCubit: Warning - First attempt to make mesh invisible failed, retrying...');
        await Future.delayed(const Duration(milliseconds: 500));
        success = await _physicsService.setMeshVisibility(false);
      }
      meshHiddenSuccessfully = success;

      if (!meshHiddenSuccessfully) {
        print(
            'InteractivePhysicsCubit: Error - Failed to make mesh invisible after multiple attempts');
      } else {
        print(
            'InteractivePhysicsCubit: Successfully hidden mesh and enabled real-world occlusion');
      }
    } catch (e) {
      print('InteractivePhysicsCubit: Error setting mesh visibility: $e');
    }
  }

  /// Starts the periodic spawning of random objects.
  void _startObjectRain() {
    _stopObjectRain(); // Ensure any existing timer is stopped before starting a new one
    _objectRainTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!state.isSimulationRunning || !state.isAlignmentComplete) {
        timer
            .cancel(); // Stop timer if simulation is no longer in the correct state
        return;
      }
      _spawnRandomObject();
    });
    print('InteractivePhysicsCubit: Object rain started.');
    // Spawn a few objects immediately to kick things off
    for (int i = 0; i < 3; i++) {
      Future.delayed(
          Duration(milliseconds: 300 * i + 100), () => _spawnRandomObject());
    }
  }

  /// Stops the periodic spawning of random objects.
  void _stopObjectRain() {
    _objectRainTimer?.cancel();
    _objectRainTimer = null;
    print('InteractivePhysicsCubit: Object rain stopped.');
  }

  /// Spawn a random object above the scene to simulate raining objects.
  Future<void> _spawnRandomObject() async {
    if (!_isARViewValid() ||
        !state.isSimulationRunning ||
        !state.isAlignmentComplete) {
      return; // Do not spawn if simulation is not ready
    }

    try {
      // Get camera position to spawn object above and slightly around it
      final cameraPosition = await _physicsService.getCameraPosition();
      if (cameraPosition == null || cameraPosition.length < 3) {
        print(
            'InteractivePhysicsCubit: Failed to get camera position for spawning object.');
        return;
      }

      // Choose random object type
      final objectTypes = PhysicsObjectType.values;
      final randomType = objectTypes[_random.nextInt(objectTypes.length)];

      // Position above camera with random horizontal offset
      final spawnPosition = [
        cameraPosition[0] +
            (_random.nextDouble() * 2.0 - 1.0) *
                1.5, // Random X offset within ±1.5m
        cameraPosition[1] +
            2.5 +
            _random.nextDouble() * 1.0, // 2.5m to 3.5m above camera
        cameraPosition[2] +
            (_random.nextDouble() * 2.0 - 1.0) *
                1.5, // Random Z offset within ±1.5m
      ];

      final object = PhysicsObject(
        id: 'rain_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
        type: randomType,
        position: spawnPosition,
        rotation: _getRandomRotation(), // Assuming _getRandomRotation() exists
        scale: _getScaleForObjectType(
            randomType), // Assuming _getScaleForObjectType() exists
        velocity: [0, -0.5, 0], // Slight initial downward velocity
        angularVelocity: [
          _random.nextDouble() * 1.0 - 0.5,
          _random.nextDouble() * 1.0 - 0.5,
          _random.nextDouble() * 1.0 - 0.5,
        ],
        mass: _getMassForObjectType(
            randomType), // Assuming _getMassForObjectType() exists
        color: _getRandomColor(), // Assuming _getRandomColor() exists
      );

      final success = await _physicsService.addPhysicsObject(object);
      if (success) {
        // Optionally, update local state if you need to track rained objects in Flutter
        // final updatedObjects = List<PhysicsObject>.from(state.objects)..add(object);
        // emit(state.copyWith(objects: updatedObjects));
        print('InteractivePhysicsCubit: Spawned random object: ${object.id}');
      } else {
        print(
            'InteractivePhysicsCubit: Failed to add rained object ${object.id} via service.');
      }
    } catch (e) {
      print('InteractivePhysicsCubit: Error spawning random object: $e');
    }
  }

  /// Get random rotation quaternion
  List<double> _getRandomRotation() {
    // Generate random euler angles
    final yaw = _random.nextDouble() * math.pi * 2;
    final pitch = _random.nextDouble() * math.pi;
    final roll = _random.nextDouble() * math.pi * 2;

    // Simple quaternion from Euler angles (not perfect but works for this)
    final cy = math.cos(yaw * 0.5);
    final sy = math.sin(yaw * 0.5);
    final cp = math.cos(pitch * 0.5);
    final sp = math.sin(pitch * 0.5);
    final cr = math.cos(roll * 0.5);
    final sr = math.sin(roll * 0.5);

    return [
      cy * cp * sr - sy * sp * cr, // x
      sy * cp * sr + cy * sp * cr, // y
      sy * cp * cr - cy * sp * sr, // z
      cy * cp * cr + sy * sp * sr, // w
    ];
  }

  /// Select an object type for placement
  void selectObjectType(PhysicsObjectType type) {
    emit(state.copyWith(selectedObjectType: type));
  }

  /// Place a new object at the tapped position
  Future<void> placeObject(double x, double y) async {
    if (_arViewId < 0 ||
        !state.isSimulationRunning ||
        !state.isAlignmentComplete) {
      print(
          'Cannot place object: ARViewId = $_arViewId, isSimulationRunning = ${state.isSimulationRunning}, isAlignmentComplete = ${state.isAlignmentComplete}');
      return;
    }

    try {
      // Convert screen coordinates to world position
      final worldPosition = await _physicsService.screenToWorldPosition(x, y);
      if (worldPosition == null) {
        print('Failed to convert screen position to world position');
        return;
      }

      print('Placing object at world position: $worldPosition');

      // Create new physics object
      final object = PhysicsObject(
        id: 'obj_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
        type: state.selectedObjectType,
        position: worldPosition,
        rotation: [0, 0, 0, 1], // Identity quaternion
        scale: _getScaleForObjectType(state.selectedObjectType),
        velocity: [0, 0, 0],
        angularVelocity: [0, 0, 0],
        mass: _getMassForObjectType(state.selectedObjectType),
        color: _getRandomColor(),
      );

      // Add object to physics simulation
      final success = await _physicsService.addPhysicsObject(object);

      if (success) {
        print('Successfully added object ${object.id}');
        final updatedObjects = List<PhysicsObject>.from(state.objects)
          ..add(object);
        emit(state.copyWith(objects: updatedObjects));
      } else {
        print('Failed to add object ${object.id}');
      }
    } catch (e) {
      // Handle error (optionally show toast or snackbar)
      debugPrint('Error placing object: $e');
    }
  }

  /// Reset the physics simulation
  Future<void> resetSimulation() async {
    if (!_isARViewValid()) return;

    _stopObjectRain(); // Stop any ongoing object rain
    try {
      await _physicsService.clearObjects();
      emit(state
          .copyWith(objects: [])); // Clear objects from Flutter state as well
      print('InteractivePhysicsCubit: Simulation reset. All objects cleared.');
      // Restart the object rain if alignment was already complete
      if (state.isAlignmentComplete) {
        _startObjectRain();
      }
    } catch (e) {
      print('InteractivePhysicsCubit: Error resetting simulation: $e');
    }
  }

  /// Stop the physics simulation completely (when exiting the view)
  void stopSimulation() {
    // Cancel all timers
    _fpsUpdateTimer?.cancel();
    _objectRainTimer?.cancel();

    // Clear state
    _objectRainTimer = null;
    _fpsUpdateTimer = null;

    print('Physics simulation stopped completely');

    // Don't need to call dispose on _physicsService here as the cubit's close method will do that
  }

  /// Toggle showing performance statistics
  void toggleStats() {
    emit(state.copyWith(showStats: !state.showStats));
  }

  /// Toggle the visibility of the scanned mesh
  ///
  /// @param visible true to show the mesh (make it opaque)
  ///               false to hide the mesh (make it invisible but maintain physics)
  Future<void> toggleMeshVisibility(bool visible) async {
    if (!_isARViewValid() || !state.isSimulationRunning) return;

    try {
      final success = await _physicsService.setMeshVisibility(visible);
      if (success) {
        print(
            'InteractivePhysicsCubit: Mesh visibility set to: ${visible ? "VISIBLE" : "HIDDEN"}');
      } else {
        print('InteractivePhysicsCubit: Failed to set mesh visibility');
      }
    } catch (e) {
      print('InteractivePhysicsCubit: Error setting mesh visibility: $e');
    }
  }

  /// Set the selected object type in the native code
  ///
  /// @param type The type of object to select (sphere, cube, cylinder, usdz)
  Future<void> setSelectedObjectType(String type) async {
    if (!_isARViewValid() || !state.isSimulationRunning) return;

    try {
      await _physicsService.setSelectedObject(type);
      print('InteractivePhysicsCubit: Selected object type set to: $type');
    } catch (e) {
      print('InteractivePhysicsCubit: Error setting object type: $e');
    }
  }

  /// Start raining objects of the selected type
  ///
  /// @param type The type of object to rain
  /// @param count The number of objects to rain
  /// @param height The height above the camera to start raining from
  Future<void> startObjectRain({
    required String type,
    int count = 30,
    double height = 2.0,
  }) async {
    if (!_isARViewValid() || !state.isSimulationRunning) return;

    try {
      await _physicsService.startObjectRain(
        type: type,
        count: count,
        height: height,
      );
      print(
          'InteractivePhysicsCubit: Started raining $count objects of type: $type');
    } catch (e) {
      print('InteractivePhysicsCubit: Error starting object rain: $e');
    }
  }

  @override
  Future<void> close() {
    _stopObjectRain(); // Stop object rain when Cubit is closed
    _fpsUpdateTimer?.cancel();
    // _physicsService.dispose(); // This is often handled by GetIt or the service itself if it has a dispose method managed elsewhere
    print('InteractivePhysicsCubit: Closed and timers cancelled.');
    return super.close();
  }

  // Helper methods
  Future<void> _updateFps() async {
    if (_arViewId < 0) return;

    try {
      final fps = await _physicsService.getFps();
      emit(state.copyWith(fps: fps));
    } catch (e) {
      debugPrint('Error updating FPS: $e');
    }
  }

  List<double> _getScaleForObjectType(PhysicsObjectType type) {
    switch (type) {
      case PhysicsObjectType.sphere:
        return [0.03, 0.03, 0.03];
      case PhysicsObjectType.cube:
        return [0.03, 0.03, 0.03];
      case PhysicsObjectType.cylinder:
        return [0.03, 0.06, 0.03];
      case PhysicsObjectType.coin:
        return [0.05, 0.008, 0.05];
    }
  }

  double _getMassForObjectType(PhysicsObjectType type) {
    switch (type) {
      case PhysicsObjectType.sphere:
        return 5.0;
      case PhysicsObjectType.cube:
        return 10.0;
      case PhysicsObjectType.cylinder:
        return 7.5;
      case PhysicsObjectType.coin:
        return 2.0;
    }
  }

  Color _getRandomColor() {
    return Color.fromRGBO(
      _random.nextInt(255),
      _random.nextInt(255),
      _random.nextInt(255),
      1.0,
    );
  }

  bool _isARViewValid() {
    return _arViewId >= 0;
  }
}
