import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lidar_scanner/feature/ar_physics/cubit/ar_physics_cubit.dart';
import 'package:lidar_scanner/feature/ar_physics/cubit/ar_physics_state.dart';
import 'package:lidar_scanner/feature/ar_physics/mixin/ar_physics_mixin.dart';
import 'package:lidar_scanner/feature/ar_physics/widgets/ar_objects_toolbar.dart';

/// AR Physics görünümü - tarama yaparken AR objeleri yerleştirmeye olanak sağlar
class ARPhysicsView extends StatefulWidget {
  /// Yeni bir AR Physics görünümü oluştur
  const ARPhysicsView({
    required this.onClose,
    super.key,
  });

  /// AR modundan çıkmak için çağrılacak callback
  final VoidCallback onClose;

  @override
  State<ARPhysicsView> createState() => _ARPhysicsViewState();
}

class _ARPhysicsViewState extends State<ARPhysicsView> with ARPhysicsMixin {
  @override
  void initState() {
    super.initState();
    arPhysicsCubit.initialize();
  }

  @override
  void dispose() {
    arPhysicsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onClose,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: arPhysicsCubit.clearAllObjects,
            tooltip: 'Tüm Objeleri Temizle',
          ),
        ],
      ),
      body: BlocBuilder<ARPhysicsCubit, ARPhysicsState>(
        bloc: arPhysicsCubit,
        builder: (context, state) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // AR Görünümü
              _ARView(physicsCubit: arPhysicsCubit),

              // Arayüz kontrollerini göster
              _buildInterface(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInterface(ARPhysicsState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Obje bilgilerini göster
        if (state.objects.isNotEmpty) _buildObjectInfo(state),

        // Obje seçim araç çubuğu
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: ARObjectsToolbar(
            selectedType: state.selectedObjectType,
            onSelectObject: arPhysicsCubit.selectObjectType,
          ),
        ),
      ],
    );
  }

  Widget _buildObjectInfo(ARPhysicsState state) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Yerleştirilmiş Objeler: ${state.objects.length}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ARView extends StatefulWidget {
  const _ARView({required this.physicsCubit});

  final ARPhysicsCubit physicsCubit;

  @override
  State<_ARView> createState() => _ARViewState();
}

class _ARViewState extends State<_ARView> {
  bool _arViewCreated = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // AR View
        UiKitView(
          viewType: 'com.example.lidarScanner/arPhysicsView',
          onPlatformViewCreated: _onViewCreated,
          creationParams: const {
            'enableTracking': true,
            'showFeaturePoints': true,
          },
          creationParamsCodec: const StandardMessageCodec(),
        ),

        // AR Görünümü üzerinde bir GestureDetector yerleştir
        if (_arViewCreated)
          GestureDetector(
            onTapDown: _handleTap,
            // Gesture detector'u saydam yap
            child: Container(color: Colors.transparent),
          ),
      ],
    );
  }

  void _onViewCreated(int id) {
    debugPrint('ARPhysicsView: View created with ID $id');
    widget.physicsCubit.setARViewId(id);

    setState(() {
      _arViewCreated = true;
    });
  }

  void _handleTap(TapDownDetails details) {
    // Ekrana dokunulduğunda obje yerleştir
    final position = details.globalPosition;
    widget.physicsCubit.placeObjectAtScreenPosition(
      position.dx,
      position.dy,
    );
  }
}
