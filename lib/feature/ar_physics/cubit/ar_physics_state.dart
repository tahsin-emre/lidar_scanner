import 'package:equatable/equatable.dart';
import 'package:lidar_scanner/product/model/physics_object.dart';

class ARPhysicsState extends Equatable {
  const ARPhysicsState({
    this.isInitialized = false,
    this.objects = const [],
    this.selectedObjectType = PhysicsObjectType.sphere,
    this.error = '',
    this.fps = 0,
  });

  final bool isInitialized;
  final List<PhysicsObject> objects;
  final PhysicsObjectType selectedObjectType;
  final String error;
  final double fps;

  ARPhysicsState copyWith({
    bool? isInitialized,
    List<PhysicsObject>? objects,
    PhysicsObjectType? selectedObjectType,
    String? error,
    double? fps,
  }) {
    return ARPhysicsState(
      isInitialized: isInitialized ?? this.isInitialized,
      objects: objects ?? this.objects,
      selectedObjectType: selectedObjectType ?? this.selectedObjectType,
      error: error ?? this.error,
      fps: fps ?? this.fps,
    );
  }

  @override
  List<Object?> get props => [
        isInitialized,
        objects,
        selectedObjectType,
        error,
        fps,
      ];
}
