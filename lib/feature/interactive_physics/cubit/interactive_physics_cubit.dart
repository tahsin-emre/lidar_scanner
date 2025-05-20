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
  int _arViewId = -1;
  final _random = math.Random();

  /// Initialize the physics environment with scan data
  Future<void> initializePhysics({required String scanPath}) async {
    emit(state.copyWith(
      isLoading: true,
      error: null,
      isAlignmentComplete: false,
      modelOffsetX: 0,
      modelOffsetY: 0,
    ));

    try {
      // Only initialize physics if ARView has been created
      if (_arViewId >= 0) {
        await _physicsService.initializePhysics(scanPath: scanPath);

        // Start FPS update timer
        _fpsUpdateTimer = Timer.periodic(
          const Duration(seconds: 1),
          (_) {
            _updateFps();
          },
        );

        emit(state.copyWith(
          isLoading: false,
          isSimulationRunning: true,
        ));
      } else {
        debugPrint('ARView not initialized yet. Waiting for view creation...');
        emit(state.copyWith(
          isLoading: false,
          error: 'AR View not initialized. Please try again.',
        ));
      }
    } on Exception catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to initialize physics: $e',
      ));
    }
  }

  /// Set the AR view ID for platform view communication
  void setARViewId(int id) {
    debugPrint('InteractivePhysicsCubit: Setting ARViewId to $id');
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
      final success = await _physicsService.adjustModelPosition(
        deltaX,
        deltaY,
      );
      if (success) {
        debugPrint(
          'InteractivePhysicsCubit: Model position adjusted successfully.',
        );
      } else {
        debugPrint(
          'InteractivePhysicsCubit: Failed to adjust model position via service.',
        );
      }
    } on Exception catch (e) {
      debugPrint('InteractivePhysicsCubit: Error adjusting model position: $e');
    }
  }

  /// Rotate the model around its Y axis
  Future<void> rotateModelY(double angle) async {
    if (_arViewId < 0 || !state.isSimulationRunning) {
      debugPrint(
        'Cannot rotate model: ARViewId = $_arViewId, '
        'isSimulationRunning = ${state.isSimulationRunning}',
      );
      return;
    }

    try {
      // Update the model rotation in the native code
      final success = await _physicsService.rotateModelY(angle);

      if (success) {
        debugPrint('Model rotated by angle: $angle');
      } else {
        debugPrint('Failed to rotate model');
      }
    } on Exception catch (e) {
      debugPrint('Error rotating model: $e');
    }
  }

  /// Zoom in/out on the model - scale factor is relative (1.0 is no change)
  Future<void> zoomModel(double scaleFactor) async {
    if (_arViewId < 0 || !state.isSimulationRunning) {
      debugPrint(
        'Cannot zoom model: ARViewId = $_arViewId, isSimulationRunning = ${state.isSimulationRunning}',
      );
      return;
    }

    try {
      // Update the model zoom in the native code
      final success = await _physicsService.zoomModel(scaleFactor);

      if (success) {
        debugPrint('Model zoomed by factor: $scaleFactor');
      } else {
        debugPrint('Failed to zoom model');
      }
    } on Exception catch (e) {
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
        debugPrint(
          'InteractivePhysicsCubit: Model position and rotation reset to origin successfully.',
        );
      } else {
        debugPrint(
          'InteractivePhysicsCubit: Failed to reset model position to origin via service.',
        );
      }
    } on Exception catch (e) {
      debugPrint(
        'InteractivePhysicsCubit: Error resetting model position to origin: $e',
      );
    }
  }

  /// Complete the alignment phase and start using the physics simulation
  Future<void> completeAlignment() async {
    if (state.isAlignmentComplete) return; // Avoid running if already complete

    emit(state.copyWith(isAlignmentComplete: true));
    debugPrint(
      'InteractivePhysicsCubit: Alignment completed. Ready for physics interaction.',
    );

    // Give a moment for the physics to stabilize before hiding mesh
    await Future<void>.delayed(const Duration(milliseconds: 500));

    var meshHiddenSuccessfully = false;
    try {
      debugPrint(
        'InteractivePhysicsCubit: Setting mesh to invisible to enable occlusion',
      );
      var success = await _physicsService.setMeshVisibility(visible: false);
      if (!success) {
        debugPrint(
          'InteractivePhysicsCubit: Warning - First attempt to make mesh '
          'invisible failed, retrying...',
        );
        await Future<void>.delayed(const Duration(milliseconds: 500));
        success = await _physicsService.setMeshVisibility(visible: false);
      }
      meshHiddenSuccessfully = success;

      if (!meshHiddenSuccessfully) {
        debugPrint(
          'InteractivePhysicsCubit: Error - Failed to make mesh invisible '
          'after multiple attempts',
        );
      } else {
        debugPrint(
          'InteractivePhysicsCubit: Successfully hidden mesh and enabled '
          'real-world occlusion',
        );
      }
    } on Exception catch (e) {
      debugPrint('InteractivePhysicsCubit: Error setting mesh visibility: $e');
    }
  }

  /// Starts the periodic spawning of random objects.

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
      debugPrint(
        'Cannot place object: ARViewId = $_arViewId, '
        'isSimulationRunning = ${state.isSimulationRunning}, '
        'isAlignmentComplete = ${state.isAlignmentComplete}',
      );
      return;
    }

    try {
      // Convert screen coordinates to world position
      final worldPosition = await _physicsService.screenToWorldPosition(x, y);
      if (worldPosition == null) {
        debugPrint('Failed to convert screen position to world position');
        return;
      }

      debugPrint('Placing object at world position: $worldPosition');
      debugPrint(
          'Current selected object type: ${state.selectedObjectType.name}');

      // Create new physics object with the currently selected object type
      final object = PhysicsObject(
        id: 'obj_${DateTime.now().millisecondsSinceEpoch}_'
            '${_random.nextInt(1000)}',
        type: state.selectedObjectType,
        position: worldPosition,
        rotation: const [0, 0, 0, 1], // Identity quaternion
        scale: _getScaleForObjectType(state.selectedObjectType),
        velocity: const [0, 0, 0],
        angularVelocity: const [0, 0, 0],
        mass: _getMassForObjectType(state.selectedObjectType),
        color: _getRandomColor(),
      );

      // Add object to physics simulation
      final success = await _physicsService.addPhysicsObject(object);

      if (success) {
        debugPrint(
            'Successfully added object ${object.id} of type ${object.type.name}');
        final updatedObjects = List<PhysicsObject>.from(state.objects)
          ..add(object);
        emit(state.copyWith(objects: updatedObjects));
      } else {
        debugPrint('Failed to add object ${object.id}');
      }
    } on Exception catch (e) {
      // Handle error (optionally show toast or snackbar)
      debugPrint('Error placing object: $e');
    }
  }

  /// Reset the physics simulation
  Future<void> resetSimulation() async {
    if (!_isARViewValid()) return;

    try {
      await _physicsService.clearObjects();
      emit(state
          .copyWith(objects: const [])); // Clear objects from Flutter state
      debugPrint(
        'InteractivePhysicsCubit: Simulation reset. All objects cleared.',
      );
    } on Exception catch (e) {
      debugPrint('InteractivePhysicsCubit: Error resetting simulation: $e');
    }
  }

  /// Stop the physics simulation completely (when exiting the view)
  void stopSimulation() {
    // Cancel all timers
    _fpsUpdateTimer?.cancel();

    // Clear state
    _fpsUpdateTimer = null;

    debugPrint('Physics simulation stopped completely');

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
  Future<void> toggleMeshVisibility({required bool isVisible}) async {
    if (!_isARViewValid() || !state.isSimulationRunning) return;

    try {
      final success =
          await _physicsService.setMeshVisibility(visible: isVisible);
      if (success) {
        debugPrint(
          'InteractivePhysicsCubit: Mesh visibility set to: '
          '${isVisible ? "VISIBLE" : "HIDDEN"}',
        );
      } else {
        debugPrint(
          'InteractivePhysicsCubit: Failed to set mesh visibility',
        );
      }
    } on Exception catch (e) {
      debugPrint('InteractivePhysicsCubit: Error setting mesh visibility: $e');
    }
  }

  /// Set the selected object type in the native code
  ///
  /// @param type The type of object to select (sphere, cube, cylinder, usdz)
  Future<void> setSelectedObjectType(String type) async {
    if (!_isARViewValid() || !state.isSimulationRunning) return;

    try {
      await _physicsService.setSelectedObject(type);

      // String tipini PhysicsObjectType'a çevir ve state'i güncelle
      PhysicsObjectType objectType;
      switch (type) {
        case 'sphere':
          objectType = PhysicsObjectType.sphere;
          break;
        case 'cube':
          objectType = PhysicsObjectType.cube;
          break;
        case 'cylinder':
          objectType = PhysicsObjectType.cylinder;
          break;
        case 'coin':
          objectType = PhysicsObjectType.coin;
          break;
        default:
          objectType =
              PhysicsObjectType.sphere; // Bilinmeyen tip için varsayılan
          break;
      }

      // State'i güncelle
      emit(state.copyWith(selectedObjectType: objectType));

      debugPrint(
        'InteractivePhysicsCubit: Selected object type set to: $type (${objectType.name})',
      );
    } on Exception catch (e) {
      debugPrint('InteractivePhysicsCubit: Error setting object type: $e');
    }
  }

  @override
  Future<void> close() {
    _fpsUpdateTimer?.cancel();
    // _physicsService.dispose(); // This is often handled by GetIt or the service itself if it has a dispose method managed elsewhere
    debugPrint('InteractivePhysicsCubit: Closed and timers cancelled.');
    return super.close();
  }

  // Helper methods
  Future<void> _updateFps() async {
    if (_arViewId < 0) return;

    try {
      final fps = await _physicsService.getFps();
      emit(state.copyWith(fps: fps));
    } on Exception catch (e) {
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
        return 5;
      case PhysicsObjectType.cube:
        return 10;
      case PhysicsObjectType.cylinder:
        return 7.5;
      case PhysicsObjectType.coin:
        return 2;
    }
  }

  Color _getRandomColor() {
    return Color.fromRGBO(
      _random.nextInt(255),
      _random.nextInt(255),
      _random.nextInt(255),
      1,
    );
  }

  bool _isARViewValid() {
    return _arViewId >= 0;
  }
}
