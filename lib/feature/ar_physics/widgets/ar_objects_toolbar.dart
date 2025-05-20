import 'package:flutter/material.dart';
import 'package:lidar_scanner/product/model/physics_object.dart';

typedef OnSelectObject = void Function(PhysicsObjectType);

class ARObjectsToolbar extends StatelessWidget {
  const ARObjectsToolbar({
    required this.selectedType,
    required this.onSelectObject,
    super.key,
  });

  final PhysicsObjectType selectedType;
  final OnSelectObject onSelectObject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildObjectButton(PhysicsObjectType.sphere),
          _buildObjectButton(PhysicsObjectType.cube),
          _buildObjectButton(PhysicsObjectType.cylinder),
          _buildObjectButton(PhysicsObjectType.coin),
        ],
      ),
    );
  }

  Widget _buildObjectButton(PhysicsObjectType type) {
    final isSelected = selectedType == type;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color:
            isSelected ? Colors.blue.withValues(alpha: .3) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: Colors.blue) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onSelectObject(type),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Icon(
                  type.icon,
                  size: 28,
                  color: isSelected ? Colors.blue : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  type.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
