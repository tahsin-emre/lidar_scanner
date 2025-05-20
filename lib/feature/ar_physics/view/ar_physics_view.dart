import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lidar_scanner/feature/ar_physics/cubit/ar_physics_cubit.dart';
import 'package:lidar_scanner/feature/ar_physics/cubit/ar_physics_state.dart';
import 'package:lidar_scanner/feature/ar_physics/mixin/ar_physics_mixin.dart';
import 'package:lidar_scanner/feature/ar_physics/widgets/ar_objects_toolbar.dart';

class ARPhysicsView extends StatefulWidget {
  const ARPhysicsView({
    required this.onClose,
    super.key,
  });
  final VoidCallback onClose;

  @override
  State<ARPhysicsView> createState() => _ARPhysicsViewState();
}

class _ARPhysicsViewState extends State<ARPhysicsView> with ARPhysicsMixin {
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
          ),
        ],
      ),
      body: BlocBuilder<ARPhysicsCubit, ARPhysicsState>(
        bloc: arPhysicsCubit,
        builder: (context, state) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _ARView(physicsCubit: arPhysicsCubit),
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
        if (state.objects.isNotEmpty) _buildObjectInfo(state),
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
        color: Colors.black.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Object Count: ${state.objects.length}',
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
        UiKitView(
          viewType: 'com.example.lidarScanner/arPhysicsView',
          onPlatformViewCreated: _onViewCreated,
          creationParams: const {
            'enableTracking': true,
            'showFeaturePoints': true,
          },
          creationParamsCodec: const StandardMessageCodec(),
        ),
        if (_arViewCreated)
          GestureDetector(
            onTapDown: _handleTap,
            child: Container(color: Colors.transparent),
          ),
      ],
    );
  }

  void _onViewCreated(int id) {
    widget.physicsCubit.setARViewId(id);
    setState(() => _arViewCreated = true);
  }

  void _handleTap(TapDownDetails details) {
    final position = details.globalPosition;
    widget.physicsCubit.placeObjectAtScreenPosition(
      position.dx,
      position.dy,
    );
  }
}
