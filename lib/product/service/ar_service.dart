import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:vector_math/vector_math_64.dart';

/// AR ile ilgili yerel platform işlemlerini yöneten servis
@singleton
class ArService {
  ArService();

  static const _channel = MethodChannel('com.example.lidarScanner/ar');

  /// Cihazın AR yeteneklerini kontrol eder
  Future<bool> checkArCapabilities() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkArCapabilities');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error checking AR capabilities: ${e.message}');
      return false;
    }
  }

  /// AR oturumunu başlatır
  Future<bool> startArSession() async {
    try {
      final result = await _channel.invokeMethod<bool>('startArSession');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error starting AR session: ${e.message}');
      return false;
    }
  }

  /// AR oturumunu durdurur
  Future<void> stopArSession() async {
    try {
      await _channel.invokeMethod('stopArSession');
    } on PlatformException catch (e) {
      print('Error stopping AR session: ${e.message}');
    }
  }

  /// 3D nesne ekler
  Future<String?> addObject({
    required String objectType,
    required Vector3 position,
    required Vector3 scale,
  }) async {
    try {
      final result = await _channel.invokeMethod<String>('addObject', {
        'objectType': objectType,
        'position': [position.x, position.y, position.z],
        'scale': [scale.x, scale.y, scale.z],
      });
      return result;
    } on PlatformException catch (e) {
      print('Error adding object: ${e.message}');
      return null;
    }
  }

  /// 3D nesneyi günceller
  Future<bool> updateObject({
    required String objectId,
    required Vector3 position,
    Vector3? rotation,
  }) async {
    try {
      final params = <String, dynamic>{
        'objectId': objectId,
        'position': [position.x, position.y, position.z],
      };

      if (rotation != null) {
        params['rotation'] = [rotation.x, rotation.y, rotation.z];
      }

      final result = await _channel.invokeMethod<bool>('updateObject', params);
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error updating object: ${e.message}');
      return false;
    }
  }

  /// 3D nesneyi kaldırır
  Future<bool> removeObject(String objectId) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'removeObject',
        {'objectId': objectId},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error removing object: ${e.message}');
      return false;
    }
  }

  /// Tüm 3D nesneleri kaldırır
  Future<bool> clearAllObjects() async {
    try {
      final result = await _channel.invokeMethod<bool>('clearAllObjects');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error clearing objects: ${e.message}');
      return false;
    }
  }

  /// Düzlem algılama durumunu ayarlar
  Future<void> setPlaneDetection(bool enabled) async {
    try {
      await _channel.invokeMethod(
        'setPlaneDetection',
        {'enabled': enabled},
      );
    } on PlatformException catch (e) {
      print('Error setting plane detection: ${e.message}');
    }
  }
}
