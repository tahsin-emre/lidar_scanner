import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:lidar_scanner/product/model/physics_object.dart';

/// Service for communicating with the native physics simulation
@singleton
class PhysicsService {
  /// Create a new physics service
  PhysicsService();

  static const _channel = MethodChannel('com.example.lidarScanner/physics');

  int _viewId = -1;

  /// Set the view ID for platform channel communication
  void setViewId(int id) {
    print('PhysicsService: Setting viewId to $id');
    _viewId = id;
  }

  /// Initialize the physics environment with the scan data
  Future<void> initializePhysics({required String scanPath}) async {
    try {
      print(
          'PhysicsService: Initializing physics with scan path: $scanPath, viewId: $_viewId');
      await _channel.invokeMethod('initializePhysics', {
        'scanPath': scanPath,
        'viewId': _viewId,
      });
      print('PhysicsService: Physics initialization completed successfully');
    } on PlatformException catch (e) {
      print('Error initializing physics: ${e.message}');
      print('Error details: ${e.details}');
      rethrow;
    } catch (e) {
      print('Unexpected error initializing physics: $e');
      rethrow;
    }
  }

  /// Convert screen coordinates to world position
  /// Returns [x, y, z] coordinates in world space
  Future<List<double>?> screenToWorldPosition(double x, double y) async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('screenToWorldPosition', {
        'x': x,
        'y': y,
        'viewId': _viewId,
      });

      if (result != null) {
        return result.map((e) => e as double).toList();
      }
      return null;
    } on PlatformException catch (e) {
      print('Error converting screen to world position: ${e.message}');
      return null;
    }
  }

  /// Add a physics object to the simulation
  Future<bool> addPhysicsObject(PhysicsObject object) async {
    try {
      print('PhysicsService: Adding object: ${object.id}, viewId: $_viewId');
      final result = await _channel.invokeMethod<bool>('addPhysicsObject', {
        'object': object.toMap(),
        'viewId': _viewId,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error adding physics object: ${e.message}');
      return false;
    }
  }

  /// Remove a physics object from the simulation
  Future<bool> removePhysicsObject(String objectId) async {
    try {
      final result = await _channel.invokeMethod<bool>('removePhysicsObject', {
        'objectId': objectId,
        'viewId': _viewId,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error removing physics object: ${e.message}');
      return false;
    }
  }

  /// Clear all physics objects from the simulation
  Future<void> clearObjects() async {
    try {
      print('PhysicsService: Clearing all objects, viewId: $_viewId');
      await _channel.invokeMethod('clearPhysicsObjects', {
        'viewId': _viewId,
      });
    } on PlatformException catch (e) {
      print('Error clearing physics objects: ${e.message}');
      rethrow;
    }
  }

  /// Apply a force to a physics object
  Future<void> applyForce({
    required String objectId,
    required List<double> force,
    required List<double> position,
  }) async {
    try {
      await _channel.invokeMethod('applyForce', {
        'objectId': objectId,
        'force': force,
        'position': position,
        'viewId': _viewId,
      });
    } on PlatformException catch (e) {
      print('Error applying force: ${e.message}');
      rethrow;
    }
  }

  /// Adjust the position of the scanned model in the physics environment
  Future<bool> adjustModelPosition(double deltaX, double deltaY) async {
    try {
      print(
          'PhysicsService: Adjusting model position with delta: ($deltaX, $deltaY), viewId: $_viewId');
      final result = await _channel.invokeMethod<bool>('adjustModelPosition', {
        'deltaX': deltaX,
        'deltaY': deltaY,
        'viewId': _viewId,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error adjusting model position: ${e.message}');
      return false;
    }
  }

  /// Set the visibility of the scanned mesh
  Future<bool> setMeshVisibility(bool visible) async {
    try {
      print(
          'PhysicsService: Setting mesh visibility to: $visible, viewId: $_viewId');
      final result = await _channel.invokeMethod<bool>('setMeshVisibility', {
        'visible': visible,
        'viewId': _viewId,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error setting mesh visibility: ${e.message}');
      return false;
    }
  }

  /// Get the current frames per second of the simulation
  Future<double> getFps() async {
    try {
      final result = await _channel.invokeMethod<double>('getFps', {
        'viewId': _viewId,
      });
      return result ?? 0.0;
    } on PlatformException catch (e) {
      print('Error getting FPS: ${e.message}');
      return 0.0;
    }
  }

  /// Set physics simulation parameters
  Future<void> setPhysicsParameters({
    double? gravity,
    double? friction,
    double? restitution,
  }) async {
    try {
      final params = <String, dynamic>{
        'viewId': _viewId,
      };

      if (gravity != null) params['gravity'] = gravity;
      if (friction != null) params['friction'] = friction;
      if (restitution != null) params['restitution'] = restitution;

      await _channel.invokeMethod('setPhysicsParameters', params);
    } on PlatformException catch (e) {
      print('Error setting physics parameters: ${e.message}');
      rethrow;
    }
  }

  /// Dispose of resources used by the physics service
  Future<void> dispose() async {
    try {
      if (_viewId >= 0) {
        await _channel.invokeMethod('disposePhysics', {
          'viewId': _viewId,
        });
      }
    } on PlatformException catch (e) {
      print('Error disposing physics service: ${e.message}');
    }
  }

  /// Get the current camera position in the AR scene
  Future<List<double>?> getCameraPosition() async {
    try {
      print('PhysicsService: Getting camera position, viewId: $_viewId');
      final result =
          await _channel.invokeMethod<List<dynamic>>('getCameraPosition', {
        'viewId': _viewId,
      });

      if (result != null) {
        return result.map((e) => e as double).toList();
      }
      return null;
    } on PlatformException catch (e) {
      print('Error getting camera position: ${e.message}');
      return null;
    }
  }

  /// Reset the model position to its origin in the native physics environment.
  Future<bool> resetModelPositionToOrigin() async {
    try {
      print(
          'PhysicsService: Resetting model position to origin, viewId: $_viewId');
      final result = await _channel.invokeMethod<bool>(
        'resetModelPositionToOrigin',
        {'viewId': _viewId}, // Ensure viewId is passed
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error resetting model position to origin: ${e.message}');
      return false;
    }
  }

  /// Rotate the model around its Y axis
  Future<bool> rotateModelY(double angle) async {
    try {
      print(
          'PhysicsService: Rotating model by angle: $angle, viewId: $_viewId');
      final result = await _channel.invokeMethod<bool>('rotateModelY', {
        'angle': angle,
        'viewId': _viewId,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error rotating model: ${e.message}');
      return false;
    }
  }
}
