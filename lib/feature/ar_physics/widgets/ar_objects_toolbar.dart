import 'package:flutter/material.dart';
import 'package:lidar_scanner/product/model/physics_object.dart';

/// AR objelerini seçmek için araç çubuğu
class ARObjectsToolbar extends StatelessWidget {
  /// Yeni bir AR objeleri araç çubuğu oluştur
  const ARObjectsToolbar({
    super.key,
    required this.selectedType,
    required this.onSelectObject,
  });

  /// Seçili obje tipi
  final PhysicsObjectType selectedType;

  /// Bir obje tipi seçildiğinde çağrılacak callback
  final void Function(PhysicsObjectType) onSelectObject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
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
        color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: Colors.blue) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onSelectObject(type),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              type.icon,
              size: 28,
              color: isSelected ? Colors.blue : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
