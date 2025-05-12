import 'package:equatable/equatable.dart';
import 'package:vector_math/vector_math_64.dart';

/// Düşen bir nesnenin durumunu temsil eden sınıf
class PhysicsObject extends Equatable {
  const PhysicsObject({
    required this.id,
    required this.position,
    required this.velocity,
    required this.objectType,
    this.isResting = false,
  });

  final String id;
  final Vector3 position;
  final Vector3 velocity;
  final String objectType;
  final bool isResting; // Nesne bir yüzeyde duruyorsa true

  PhysicsObject copyWith({
    String? id,
    Vector3? position,
    Vector3? velocity,
    String? objectType,
    bool? isResting,
  }) {
    return PhysicsObject(
      id: id ?? this.id,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      objectType: objectType ?? this.objectType,
      isResting: isResting ?? this.isResting,
    );
  }

  @override
  List<Object?> get props => [id, position, velocity, objectType, isResting];
}

/// AR fizik modülünün durumunu temsil eden sınıf
class ArPhysicsState extends Equatable {
  ArPhysicsState({
    this.isInitialized = false,
    this.isPlaneDetected = false,
    this.physicsObjects = const [],
    Vector3? gravity,
    this.isPaused = false,
  }) : gravity = gravity ??
            Vector3(0, -9.81, 0); // Yerçekimi vektörü (y ekseni aşağı doğru)

  final bool isInitialized;
  final bool isPlaneDetected;
  final List<PhysicsObject> physicsObjects;
  final Vector3 gravity;
  final bool isPaused;

  ArPhysicsState copyWith({
    bool? isInitialized,
    bool? isPlaneDetected,
    List<PhysicsObject>? physicsObjects,
    Vector3? gravity,
    bool? isPaused,
  }) {
    return ArPhysicsState(
      isInitialized: isInitialized ?? this.isInitialized,
      isPlaneDetected: isPlaneDetected ?? this.isPlaneDetected,
      physicsObjects: physicsObjects ?? this.physicsObjects,
      gravity: gravity ?? this.gravity,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  @override
  List<Object?> get props => [
        isInitialized,
        isPlaneDetected,
        physicsObjects,
        gravity,
        isPaused,
      ];
}
