import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lidar_scanner/feature/interactive_physics/cubit/interactive_physics_cubit.dart'
    as physics_cubit;
import 'package:lidar_scanner/feature/interactive_physics/cubit/interactive_physics_state.dart'
    as physics_state;
import 'package:lidar_scanner/feature/interactive_physics/mixin/interactive_physics_mixin.dart';

/// View for the interactive physics feature that allows users to place virtual objects
class InteractivePhysicsView extends StatefulWidget {
  const InteractivePhysicsView({
    required this.scanPath,
    super.key,
  });

  /// Path to the scanned model file (.obj)
  final String scanPath;

  @override
  State<InteractivePhysicsView> createState() => _InteractivePhysicsViewState();
}

class _InteractivePhysicsViewState extends State<InteractivePhysicsView>
    with InteractivePhysicsMixin {
  @override
  void initState() {
    super.initState();
    // Physics will be initialized after AR view is created
  }

  @override
  void dispose() {
    // Ensure we clean up and stop physics when leaving this screen
    physicsCubit.stopSimulation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Interactive Physics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black54,
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.black.withOpacity(0.4),
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.restart_alt,
              color: Colors.white,
              size: 28,
            ),
            tooltip: 'Reset simulation',
            onPressed: physicsCubit.resetSimulation,
          ),
        ],
      ),
      body: BlocBuilder<physics_cubit.InteractivePhysicsCubit,
          physics_state.InteractivePhysicsState>(
        bloc: physicsCubit,
        builder: (context, state) {
          return Stack(
            children: [
              // ARView showing the scanned environment with physics objects
              _PhysicsARView(
                physicsCubit: physicsCubit,
                scanPath: widget.scanPath,
                onTap: (position) =>
                    onTapToPlaceObject(position.dx, position.dy),
                // Only allow model adjustment if alignment is not complete
                onAdjustPosition: !state.isAlignmentComplete
                    ? (dx, dy) {
                        physicsCubit.adjustModelPosition(dx, dy);
                      }
                    : null,
                onRotationUpdate: !state.isAlignmentComplete
                    ? (angle) {
                        physicsCubit.rotateModelY(angle * 0.05);
                      }
                    : null,
                onZoomUpdate: !state.isAlignmentComplete
                    ? (scale) {
                        physicsCubit.zoomModel(scale);
                      }
                    : null,
              ),

              // Loading indicator
              if (state.isLoading)
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Loading physics environment...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

              // Error message
              if (state.error != null && !state.isLoading)
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.shade300,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 50,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hata Oluştu',
                          style: TextStyle(
                            color: Colors.red.shade300,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${state.error}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tekrar Dene'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shadowColor: Colors.red.shade900,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onPressed: () {
                            physicsCubit.initializePhysics(
                                scanPath: widget.scanPath);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              // Object type selector (only show when not loading and no error)
              if (!state.isLoading && state.error == null)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // World alignment controls
                      if (!state.isAlignmentComplete)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _AlignmentControls(
                            onConfirmAlignment: () {
                              physicsCubit.completeAlignment();
                            },
                            onAdjustPosition: (dx, dy) {
                              physicsCubit.adjustModelPosition(dx, dy);
                            },
                            onResetAlignment: () {
                              physicsCubit.resetAlignment();
                            },
                          ),
                        ),
                      // Object toolbar is optional after alignment is complete
                      if (state.isAlignmentComplete)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ObjectControls(
                            onClearObjects: () {
                              physicsCubit.resetSimulation();
                            },
                            physicsCubit: physicsCubit,
                          ),
                        ),
                    ],
                  ),
                ),

              // Stats display (optional)
              if (state.showStats && !state.isLoading && state.error == null)
                Positioned(
                  top: 120,
                  right: 6,
                  child: _StatsOverlay(
                    objectCount: state.objects.length,
                    fps: state.fps,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void onTapToPlaceObject(double x, double y) {
    physicsCubit.placeObject(x, y);
  }
}

class _PhysicsARView extends StatefulWidget {
  const _PhysicsARView({
    required this.physicsCubit,
    required this.scanPath,
    required this.onTap,
    required this.onAdjustPosition,
    required this.onRotationUpdate,
    required this.onZoomUpdate,
  });

  final physics_cubit.InteractivePhysicsCubit physicsCubit;
  final String scanPath;
  final void Function(Offset position) onTap;
  final void Function(double offsetX, double offsetY)? onAdjustPosition;
  final void Function(double angle)? onRotationUpdate;
  final void Function(double scale)? onZoomUpdate;

  @override
  State<_PhysicsARView> createState() => _PhysicsARViewState();
}

class _PhysicsARViewState extends State<_PhysicsARView> {
  bool _arViewCreated = false;
  double _previousScale = 1;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // AR View
        SizedBox.expand(
          child: UiKitView(
            viewType: 'com.example.lidarScanner/physicsView',
            onPlatformViewCreated: _onPlatformViewCreated,
            creationParams: const {
              'initialConfiguration': {
                'gravity': -9.8,
                'restitution': 0.7,
                'friction': 0.3,
                'enableDebugVisualization': true,
              }
            },
            creationParamsCodec: const StandardMessageCodec(),
          ),
        ),

        // Gesture detector overlay
        if (_arViewCreated)
          Positioned.fill(
            child: GestureDetector(
              onTapUp: (details) => widget.onTap(details.localPosition),
              onScaleStart: (details) {
                _previousScale = 1.0;
              },
              onScaleUpdate: (details) {
                if (details.pointerCount == 1) {
                  widget.onAdjustPosition?.call(
                    details.focalPointDelta.dx,
                    details.focalPointDelta.dy,
                  );
                } else if (details.pointerCount == 2) {
                  if (details.rotation != 0.0 &&
                      widget.onRotationUpdate != null) {
                    final angle = details.rotation * 180 / math.pi;
                    widget.onRotationUpdate!(angle);
                  }

                  if (details.scale != 1.0 && widget.onZoomUpdate != null) {
                    final relativeScale = details.scale / _previousScale;
                    _previousScale = details.scale;

                    if (relativeScale < 95 / 100 || relativeScale > 105 / 100) {
                      widget.onZoomUpdate!(relativeScale);
                    }
                  }
                }
              },
              // Make the gesture detector transparent
              child: Container(color: Colors.transparent),
            ),
          ),
      ],
    );
  }

  void _onPlatformViewCreated(int id) {
    debugPrint('PhysicsARView: View created with ID $id');
    widget.physicsCubit.setARViewId(id);

    // Initialize physics after AR view is created
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.physicsCubit.initializePhysics(scanPath: widget.scanPath);
      setState(() {
        _arViewCreated = true;
      });
    });
  }
}

class _StatsOverlay extends StatelessWidget {
  const _StatsOverlay({
    required this.objectCount,
    required this.fps,
  });

  final int objectCount;
  final double fps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Objects: $objectCount',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            'FPS: ${fps.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _AlignmentControls extends StatelessWidget {
  const _AlignmentControls({
    required this.onConfirmAlignment,
    required this.onAdjustPosition,
    required this.onResetAlignment,
  });

  final VoidCallback onConfirmAlignment;
  final void Function(double dx, double dy) onAdjustPosition;
  final VoidCallback onResetAlignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 221,
          red: 0,
          green: 0,
          blue: 0,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Drag to move, pinch and rotate with two fingers to turn the '
              'model',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Reset',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: onResetAlignment,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.withValues(
                    alpha: 128,
                    red: 255,
                    green: 0,
                    blue: 0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.check_circle, color: Colors.black),
                label: const Text(
                  'Confirm',
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: onConfirmAlignment,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green.withValues(
                    alpha: 204,
                    red: 76,
                    green: 175,
                    blue: 80,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Movement precision values
enum _MovementPrecisionValue {
  fine(1 / 100, 'Fine'),
  medium(5 / 100, 'Medium'),
  coarse(1 / 10, 'Coarse');

  const _MovementPrecisionValue(this.value, this.label);
  final double value;
  final String label;
}

// Singleton to track current precision
class _MovementPrecision {
  static _MovementPrecisionValue current = _MovementPrecisionValue.medium;
}

// Precision selector widget
class _PrecisionSelector extends StatefulWidget {
  @override
  State<_PrecisionSelector> createState() => _PrecisionSelectorState();
}

class _PrecisionSelectorState extends State<_PrecisionSelector> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Precision: ',
          style: TextStyle(color: Colors.white),
        ),
        const SizedBox(width: 8),
        SegmentedButton<_MovementPrecisionValue>(
          segments: _MovementPrecisionValue.values
              .map((p) => ButtonSegment<_MovementPrecisionValue>(
                    value: p,
                    label: Text(p.label, style: const TextStyle(fontSize: 12)),
                  ))
              .toList(),
          selected: {_MovementPrecision.current},
          onSelectionChanged: (Set<_MovementPrecisionValue> selection) {
            setState(() {
              _MovementPrecision.current = selection.first;
            });
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.blue;
                }
                return Colors.grey;
              },
            ),
            foregroundColor: WidgetStateProperty.all(Colors.blue),
          ),
        ),
      ],
    );
  }
}

class _ObjectControls extends StatefulWidget {
  const _ObjectControls({
    required this.onClearObjects,
    required this.physicsCubit,
  });

  final VoidCallback onClearObjects;
  final physics_cubit.InteractivePhysicsCubit physicsCubit;

  @override
  State<_ObjectControls> createState() => _ObjectControlsState();
}

class _ObjectControlsState extends State<_ObjectControls> {
  bool _isMeshVisible = false;
  String _selectedObjectType = 'sphere';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.85),
            Colors.blueGrey.withOpacity(0.7),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Eklemek İstediğiniz Objeyi Seçin',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _buildObjectSelector(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildMeshButton(),
              _buildClearButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeshButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isMeshVisible
              ? [Colors.orange.shade400, Colors.deepOrange.shade600]
              : [Colors.blue.shade400, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _isMeshVisible
                ? Colors.orange.withOpacity(0.4)
                : Colors.blue.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isMeshVisible = !_isMeshVisible;
            });
            widget.physicsCubit.toggleMeshVisibility(isVisible: _isMeshVisible);
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white24,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isMeshVisible ? Icons.grid_off : Icons.grid_on,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isMeshVisible ? 'Hide Mesh' : 'Show Mesh',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.deepOrange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onClearObjects,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white24,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.delete_sweep,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Clear All',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildObjectSelector() {
    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          _objectOption('sphere', 'Sphere', Icons.circle),
          _objectOption('cube', 'Cube', Icons.crop_square_sharp),
          _objectOption('cylinder', 'Cylinder', Icons.crop_portrait),
          _objectOption('coin', 'Coin', Icons.monetization_on),
        ],
      ),
    );
  }

  Widget _objectOption(String type, String label, IconData icon) {
    final isSelected = _selectedObjectType == type;

    // Obje tipine göre özel renkler
    Color getColorForType(String type, bool isSelected) {
      if (!isSelected) return Colors.grey.shade800;

      switch (type) {
        case 'sphere':
          return Colors.blue.shade500;
        case 'cube':
          return Colors.purple.shade500;
        case 'cylinder':
          return Colors.teal.shade500;
        case 'coin':
          return Colors.amber.shade600;
        case 'usdz':
          return Colors.green.shade500;
        default:
          return Colors.blue.shade500;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: getColorForType(type, isSelected),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? getColorForType(type, true).withOpacity(0.6)
                : Colors.black.withOpacity(0.2),
            blurRadius: isSelected ? 8 : 2,
            spreadRadius: isSelected ? 2 : 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedObjectType = type;
            });
            widget.physicsCubit.setSelectedObjectType(type);
          },
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: isSelected ? 32 : 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                  shadows: isSelected
                      ? [
                          const Shadow(
                              color: Colors.black54,
                              blurRadius: 2,
                              offset: Offset(0, 1))
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
