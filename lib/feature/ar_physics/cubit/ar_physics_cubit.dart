import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lidar_scanner/feature/ar_physics/cubit/ar_physics_state.dart';
import 'package:vector_math/vector_math_64.dart';

@injectable
class ArPhysicsCubit extends Cubit<ArPhysicsState> {
  ArPhysicsCubit() : super(ArPhysicsState());

  Timer? _physicsTimer;
  final _random = math.Random();
  static const _physicsUpdateInterval = Duration(milliseconds: 16); // ~60 FPS
  static const _objectTypes = ['sphere', 'cube']; // Desteklenen nesne tipleri

  /// AR görünümü başlatır
  void initialize() {
    emit(state.copyWith(isInitialized: true));
  }

  /// Düz yüzey (plane) algılandığında çağrılır
  void onPlaneDetected() {
    emit(state.copyWith(isPlaneDetected: true));
  }

  /// Fizik simülasyonunu başlatır
  void startPhysicsSimulation() {
    if (_physicsTimer != null) return;

    _physicsTimer = Timer.periodic(_physicsUpdateInterval, _updatePhysics);
    emit(state.copyWith(isPaused: false));
  }

  /// Fizik simülasyonunu duraklatır
  void pausePhysicsSimulation() {
    _physicsTimer?.cancel();
    _physicsTimer = null;
    emit(state.copyWith(isPaused: true));
  }

  /// Rastgele bir nesne ekler
  void addRandomObject({required Vector3 position}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final objectType = _objectTypes[_random.nextInt(_objectTypes.length)];

    // Rastgele başlangıç hızı (x ve z eksenlerinde)
    final velocity = Vector3(
      _random.nextDouble() * 0.5 - 0.25, // -0.25 ile 0.25 arasında
      0, // Başlangıçta dikey hız yok
      _random.nextDouble() * 0.5 - 0.25, // -0.25 ile 0.25 arasında
    );

    final newObject = PhysicsObject(
      id: id,
      position: position,
      velocity: velocity,
      objectType: objectType,
    );

    final updatedObjects = List<PhysicsObject>.from(state.physicsObjects)
      ..add(newObject);

    emit(state.copyWith(physicsObjects: updatedObjects));
  }

  /// Belirli bir nesneyi kaldırır
  void removeObject(String id) {
    final updatedObjects =
        state.physicsObjects.where((object) => object.id != id).toList();

    emit(state.copyWith(physicsObjects: updatedObjects));
  }

  /// Tüm nesneleri kaldırır
  void clearAllObjects() {
    emit(state.copyWith(physicsObjects: []));
  }

  /// Fizik simülasyonunu günceller
  void _updatePhysics(Timer timer) {
    if (state.physicsObjects.isEmpty) return;

    final updatedObjects = <PhysicsObject>[];

    for (final object in state.physicsObjects) {
      if (object.isResting) {
        // Zaten duran nesneler için güncelleme yapmıyoruz
        updatedObjects.add(object);
        continue;
      }

      // Yerçekimi etkisi ile hız güncelleniyor
      final updatedVelocity = object.velocity +
          state.gravity * (_physicsUpdateInterval.inMilliseconds / 1000);

      // Konum güncelleniyor
      final updatedPosition = object.position +
          updatedVelocity * (_physicsUpdateInterval.inMilliseconds / 1000);

      // Yüzey kontrolü (basit bir örnek: y=0 düzlemi)
      bool isResting = false;
      Vector3 finalPosition = updatedPosition.clone();
      Vector3 finalVelocity = updatedVelocity.clone();

      if (updatedPosition.y <= 0) {
        // Nesne yere çarptı
        finalPosition.y = 0; // Yerin altına geçmesini engelle

        // Zıplama etkisi (enerji kaybı ile)
        if (updatedVelocity.y < -0.1) {
          // Hızın büyüklüğü belirli bir eşiğin üzerindeyse zıpla
          finalVelocity.y = -updatedVelocity.y * 0.6; // %60 enerji korunumu

          // Sürtünme etkisi ile x ve z hızları azalır
          finalVelocity.x *= 0.9;
          finalVelocity.z *= 0.9;
        } else {
          // Çok yavaşsa artık durur
          finalVelocity = Vector3.zero();
          isResting = true;
        }
      }

      updatedObjects.add(
        object.copyWith(
          position: finalPosition,
          velocity: finalVelocity,
          isResting: isResting,
        ),
      );
    }

    emit(state.copyWith(physicsObjects: updatedObjects));
  }

  @override
  Future<void> close() {
    _physicsTimer?.cancel();
    return super.close();
  }
}
