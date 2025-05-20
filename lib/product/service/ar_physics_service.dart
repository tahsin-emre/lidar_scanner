import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:lidar_scanner/product/model/physics_object.dart';
import 'package:logging/logging.dart';

@singleton
class ARPhysicsService {
  ARPhysicsService() {
    _logger = Logger('ARPhysicsService');
  }

  late final Logger _logger;
  int _viewId = -1;

  String _getChannelName(int viewId) {
    return 'com.example.lidarScanner/arPhysics_$viewId';
  }

  MethodChannel _getMethodChannel([int? viewId]) {
    final id = viewId ?? _viewId;
    return MethodChannel(_getChannelName(id));
  }

  void setViewId(int id) {
    _logger.info('Setting AR Physics viewId to $id');
    _viewId = id;
  }

  Future<List<double>?> screenToWorldPosition(double x, double y) async {
    if (_viewId < 0) {
      _logger.warning('AR View not initialized, cannot convert position');
      return null;
    }

    try {
      _logger.info('Converting screen position ($x, $y) to world position');
      final channel = _getMethodChannel();

      final result =
          await channel.invokeMethod<List<dynamic>>('screenToWorldPosition', {
        'x': x,
        'y': y,
        'viewId': _viewId,
      });

      if (result != null) {
        final convertedResult = result.map((e) => e as double).toList();
        _logger.info('Position converted successfully: $convertedResult');
        return convertedResult;
      }

      _logger.warning('Received null result from screenToWorldPosition');
      return null;
    } on PlatformException catch (e) {
      _logger
        ..warning('Error converting screen to world position: ${e.message}')
        ..warning('Error details: ${e.details}');
      return null;
    }
  }

  Future<bool> addPhysicsObject(PhysicsObject object) async {
    if (_viewId < 0) {
      _logger.warning('AR View not initialized, cannot add object');
      return false;
    }

    try {
      _logger
        ..info('Adding object ${object.id} to AR view $_viewId')
        ..info('Object data: ${object.toMap()}');

      final channel = _getMethodChannel();

      final result = await channel.invokeMethod<bool>('addPhysicsObject', {
        'object': object.toMap(),
        'viewId': _viewId,
      });

      _logger.info('Object added successfully: ${result ?? false}');
      return result ?? false;
    } on PlatformException catch (e) {
      _logger
        ..warning('Error adding physics object: ${e.message}')
        ..warning('Error details: ${e.details}');
      return false;
    }
  }

  Future<bool> removePhysicsObject(String objectId) async {
    if (_viewId < 0) {
      _logger.warning('AR View not initialized, cannot remove object');
      return false;
    }

    try {
      _logger.info('Removing object $objectId from AR view $_viewId');

      final channel = _getMethodChannel();

      final result = await channel.invokeMethod<bool>('removePhysicsObject', {
        'objectId': objectId,
        'viewId': _viewId,
      });

      return result ?? false;
    } on PlatformException catch (e) {
      _logger.warning('Error removing physics object: ${e.message}');
      return false;
    }
  }

  Future<bool> clearObjects() async {
    if (_viewId < 0) {
      _logger.warning('AR View not initialized, cannot clear objects');
      return false;
    }

    try {
      _logger.info('Clearing all objects from AR view $_viewId');

      final channel = _getMethodChannel();

      await channel.invokeMethod<void>('clearPhysicsObjects', {
        'viewId': _viewId,
      });

      return true;
    } on PlatformException catch (e) {
      _logger.warning('Error clearing physics objects: ${e.message}');
      return false;
    }
  }

  Future<double> getFps() async {
    if (_viewId < 0) return 0.0;

    try {
      final channel = _getMethodChannel();

      final result = await channel.invokeMethod<double>('getFps', {
        'viewId': _viewId,
      });

      return result ?? 0.0;
    } on PlatformException catch (e) {
      _logger.warning('Error getting FPS: ${e.message}');
      return 0.0;
    }
  }
}
