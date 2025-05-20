import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:lidar_scanner/product/model/physics_object.dart';
import 'package:logging/logging.dart';

/// AR Fizik modülü ile iletişim kurmak için servis sınıfı
@singleton
class ARPhysicsService {
  /// Yeni bir AR Fizik servisi oluştur
  ARPhysicsService() {
    _logger = Logger('ARPhysicsService');
  }

  late final Logger _logger;
  int _viewId = -1;

  /// Method channel'ın adını belirli bir viewId için oluşturur
  String _getChannelName(int viewId) {
    return 'com.example.lidarScanner/arPhysics_$viewId';
  }

  /// Mevcut yada belirtilen viewId için method channel oluşturur
  MethodChannel _getMethodChannel([int? viewId]) {
    final id = viewId ?? _viewId;
    return MethodChannel(_getChannelName(id));
  }

  /// ViewId'yi ayarla
  void setViewId(int id) {
    _logger.info('Setting AR Physics viewId to $id');
    _viewId = id;
  }

  /// Ekran koordinatlarını dünya koordinatlarına dönüştür
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
          .warning('Error converting screen to world position: ${e.message}');
      _logger.warning('Error details: ${e.details}');
      return null;
    } catch (e) {
      _logger.warning('Unexpected error during position conversion: $e');
      return null;
    }
  }

  /// AR sahnesi'ne fizik objesi ekle
  Future<bool> addPhysicsObject(PhysicsObject object) async {
    if (_viewId < 0) {
      _logger.warning('AR View not initialized, cannot add object');
      return false;
    }

    try {
      _logger.info('Adding object ${object.id} to AR view $_viewId');
      _logger.info('Object data: ${object.toMap()}');

      final channel = _getMethodChannel();

      final result = await channel.invokeMethod<bool>('addPhysicsObject', {
        'object': object.toMap(),
        'viewId': _viewId,
      });

      _logger.info('Object added successfully: ${result ?? false}');
      return result ?? false;
    } on PlatformException catch (e) {
      _logger.warning('Error adding physics object: ${e.message}');
      _logger.warning('Error details: ${e.details}');
      return false;
    } catch (e) {
      _logger.warning('Unexpected error adding object: $e');
      return false;
    }
  }

  /// Belli bir objeyi AR sahnesinden kaldır
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

  /// Tüm objeleri AR sahnesinden temizle
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

  /// Fizik simülasyonu FPS değerini al
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
