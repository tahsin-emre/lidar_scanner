// ignore_for_file: deprecated_member_use, document_ignores

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum PhysicsObjectType {
  sphere,
  cube,
  cylinder,
  coin;

  IconData get icon {
    switch (this) {
      case PhysicsObjectType.sphere:
        return Icons.circle_outlined;
      case PhysicsObjectType.cube:
        return Icons.crop_square_outlined;
      case PhysicsObjectType.cylinder:
        return Icons.toll_outlined;
      case PhysicsObjectType.coin:
        return Icons.monetization_on_outlined;
    }
  }

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

class PhysicsObject extends Equatable {
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

  final String id;
  final PhysicsObjectType type;
  final List<double> position;
  final List<double> rotation;
  final List<double> scale;
  final List<double> velocity;
  final List<double> angularVelocity;
  final double mass;
  final Color color;
  final bool isStatic;

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
