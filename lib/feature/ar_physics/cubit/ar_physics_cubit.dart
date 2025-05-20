import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lidar_scanner/feature/ar_physics/cubit/ar_physics_state.dart';
import 'package:lidar_scanner/feature/ar_physics/service/ar_physics_service.dart';
import 'package:lidar_scanner/product/model/physics_object.dart';

/// AR Fizik modülünün mantığını yöneten Cubit sınıfı
@injectable
class ARPhysicsCubit extends Cubit<ARPhysicsState> {
  /// Yeni bir AR Fizik Cubit oluştur
  ARPhysicsCubit(this._arPhysicsService) : super(const ARPhysicsState());

  final ARPhysicsService _arPhysicsService;
  final math.Random _random = math.Random();

  Timer? _fpsUpdateTimer;
  int _arViewId = -1;

  /// AR Fizik modülünü başlat
  Future<void> initialize() async {
    emit(state.copyWith(isInitialized: false, error: ''));

    // FPS güncellemesi için zamanlayıcı başlat
    _fpsUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateFps(),
    );
  }

  /// AR görünümü için viewId'yi ayarla
  void setARViewId(int id) {
    debugPrint('ARPhysicsCubit: Setting ARViewId to $id');
    _arViewId = id;

    // AR servisi için viewId'yi ayarla
    _arPhysicsService.setViewId(id);

    emit(state.copyWith(
      isInitialized: true,
      error: '',
    ));

    // ID ayarlandıktan hemen sonra tüm objeleri temizle
    // Eski viewId'den kalan objeleri temizlemek için
    _arPhysicsService.clearObjects().then((_) {
      debugPrint('ARPhysicsCubit: Initial clear objects completed');
    }).catchError((error) {
      debugPrint('ARPhysicsCubit: Error during initial clear: $error');
    });
  }

  /// Ekrandaki bir pozisyona obje yerleştir
  Future<void> placeObjectAtScreenPosition(double x, double y) async {
    if (!_isARViewValid()) {
      emit(state.copyWith(
        error: 'AR View not initialized. Please try again.',
      ));
      debugPrint('ARPhysicsCubit: Invalid AR View ID: $_arViewId');
      return;
    }

    try {
      debugPrint(
          'Attempting to place object at screen position: $x, $y with viewId: $_arViewId');

      // Ekran koordinatlarını dünya koordinatlarına çevir
      final worldPosition = await _arPhysicsService.screenToWorldPosition(x, y);

      if (worldPosition == null) {
        debugPrint(
            'Could not convert screen position to world position, using default position');
        // Dünya pozisyonu boşsa, önünüze bir obje yerleştirin (kameradan biraz ileride)
        // Burada varsayılan bir pozisyon veriyoruz
        _addObjectAtPosition([0, 0, -0.5]);
        return;
      }

      debugPrint('Successfully converted to world position: $worldPosition');
      _addObjectAtPosition(worldPosition);
    } catch (e) {
      debugPrint('Error placing object: $e');
      // Hata durumunda bile bir obje yerleştirmeyi deneyelim
      _addObjectAtPosition([0, 0, -0.5]);
    }
  }

  /// Belirtilen dünya pozisyonunda bir obje ekle
  void _addObjectAtPosition(List<double> position) {
    // Rastgele renk oluştur
    final color = Color.fromRGBO(
      _random.nextInt(200) + 55,
      _random.nextInt(200) + 55,
      _random.nextInt(200) + 55,
      1,
    );

    // Obje oluştur
    final newObject = PhysicsObject(
      id: 'obj_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}',
      type: state.selectedObjectType,
      position: position,
      rotation: [0, 0, 0, 1], // Quaternion
      scale: [1, 1, 1],
      velocity: [0, 0, 0],
      angularVelocity: [0, 0, 0],
      mass: 1.0,
      color: color,
    );

    _arPhysicsService.addPhysicsObject(newObject).then((success) {
      if (success) {
        final updatedObjects = List<PhysicsObject>.from(state.objects)
          ..add(newObject);

        emit(state.copyWith(objects: updatedObjects));
        debugPrint('Object added successfully at position: $position');
      } else {
        debugPrint('Failed to add object via physics service');
      }
    }).catchError((error) {
      debugPrint('Error adding physics object: $error');
    });
  }

  /// Tüm objeleri temizle
  Future<void> clearAllObjects() async {
    if (!_isARViewValid()) return;

    await _arPhysicsService.clearObjects();
    emit(state.copyWith(objects: const []));

    debugPrint('ARPhysicsCubit: All objects cleared.');
  }

  /// Seçili obje tipini değiştir
  void selectObjectType(PhysicsObjectType type) {
    if (state.selectedObjectType != type) {
      emit(state.copyWith(selectedObjectType: type));
    }
  }

  /// FPS değerini güncelle
  Future<void> _updateFps() async {
    if (!_isARViewValid()) return;

    try {
      final fps = await _arPhysicsService.getFps();
      if (fps > 0) {
        emit(state.copyWith(fps: fps));
      }
    } catch (e) {
      // FPS güncellemesi başarısız olsa bile sessizce devam et
    }
  }

  /// Kaynakları temizle
  @override
  Future<void> close() async {
    _fpsUpdateTimer?.cancel();
    _fpsUpdateTimer = null;

    await super.close();
  }

  /// ARView ID'sinin geçerli olup olmadığını kontrol et
  bool _isARViewValid() {
    return _arViewId >= 0;
  }
}
