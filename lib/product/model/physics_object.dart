import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Types of physics objects that can be placed in the simulation
enum PhysicsObjectType {
  /// Spherical object (ball)
  sphere,

  /// Cube object
  cube,

  /// Cylinder object
  cylinder,

  /// Coin object (madeni para)
  coin;

  /// Get an icon for this object type
  IconData get icon {
    switch (this) {
      case PhysicsObjectType.sphere:
        return Icons.circle;
      case PhysicsObjectType.cube:
        return Icons.crop_square;
      case PhysicsObjectType.cylinder:
        return Icons.toll;
      case PhysicsObjectType.coin:
        return Icons.monetization_on;
    }
  }

  /// Get a name for this object type
  String get displayName {
    switch (this) {
      case PhysicsObjectType.sphere:
        return 'Sphere';
      case PhysicsObjectType.cube:
        return 'Cube';
      case PhysicsObjectType.cylinder:
        return 'Cylinder';
      case PhysicsObjectType.coin:
        return 'Coin';
    }
  }
}

/// Represents a physics object in the simulation
class PhysicsObject extends Equatable {
  /// Create a new physics object
  const PhysicsObject({
    required this.id,
    required this.type,
    required this.position,
    required this.rotation,
    required this.scale,
    required this.velocity,
    required this.angularVelocity,
    required this.mass,
    required this.color,
    this.isStatic = false,
  });

  /// Unique identifier for this object
  final String id;

  /// Type of physics object
  final PhysicsObjectType type;

  /// Position in 3D space (x, y, z)
  final List<double> position;

  /// Rotation in 3D space (x, y, z, w quaternion)
  final List<double> rotation;

  /// Scale in 3D space (x, y, z)
  final List<double> scale;

  /// Linear velocity (x, y, z)
  final List<double> velocity;

  /// Angular velocity (x, y, z)
  final List<double> angularVelocity;

  /// Mass of the object
  final double mass;

  /// Color of the object
  final Color color;

  /// Whether the object is static (immovable)
  final bool isStatic;

  /// Create a copy with updated properties
  PhysicsObject copyWith({
    String? id,
    PhysicsObjectType? type,
    List<double>? position,
    List<double>? rotation,
    List<double>? scale,
    List<double>? velocity,
    List<double>? angularVelocity,
    double? mass,
    Color? color,
    bool? isStatic,
  }) {
    return PhysicsObject(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      velocity: velocity ?? this.velocity,
      angularVelocity: angularVelocity ?? this.angularVelocity,
      mass: mass ?? this.mass,
      color: color ?? this.color,
      isStatic: isStatic ?? this.isStatic,
    );
  }

  /// Convert to a map for sending to native code
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'position': position,
      'rotation': rotation,
      'scale': scale,
      'velocity': velocity,
      'angularVelocity': angularVelocity,
      'mass': mass,
      'color': [
        color.red,
        color.green,
        color.blue,
        color.alpha,
      ],
      'isStatic': isStatic,
    };
  }

  @override
  List<Object?> get props => [
        id,
        type,
        position,
        rotation,
        scale,
        velocity,
        angularVelocity,
        mass,
        color,
        isStatic,
      ];
}
