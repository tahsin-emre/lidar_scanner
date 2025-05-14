import 'package:flutter/material.dart';
import 'package:lidar_scanner/product/model/physics_object.dart';

/// A toolbar for selecting different types of physics objects
class ObjectToolbar extends StatelessWidget {
  /// Create a new object toolbar
  const ObjectToolbar({
    required this.selectedObjectType,
    required this.onObjectSelected,
    super.key,
  });

  /// Currently selected object type
  final PhysicsObjectType selectedObjectType;

  /// Callback when an object type is selected
  final void Function(PhysicsObjectType) onObjectSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: PhysicsObjectType.values
            .map((type) => _buildObjectButton(context, type))
            .toList(),
      ),
    );
  }

  Widget _buildObjectButton(BuildContext context, PhysicsObjectType type) {
    final isSelected = type == selectedObjectType;

    return GestureDetector(
      onTap: () => onObjectSelected(type),
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type.icon,
              size: 32,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).iconTheme.color,
            ),
            const SizedBox(height: 4),
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
