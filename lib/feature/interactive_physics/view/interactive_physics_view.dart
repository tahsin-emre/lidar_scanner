import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lidar_scanner/feature/interactive_physics/cubit/interactive_physics_cubit.dart';
import 'package:lidar_scanner/feature/interactive_physics/cubit/interactive_physics_state.dart';
import 'package:lidar_scanner/feature/interactive_physics/mixin/interactive_physics_mixin.dart';
import 'package:lidar_scanner/feature/interactive_physics/widgets/object_toolbar.dart';
import 'package:lidar_scanner/product/model/physics_object.dart';
import 'dart:math' as math;

/// View for the interactive physics feature that allows users to place virtual objects
/// in their scanned environment and watch them interact with real-world objects.
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
      appBar: AppBar(
        title: const Text('Interactive Physics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset simulation',
            onPressed: physicsCubit.resetSimulation,
          ),
        ],
      ),
      body: BlocBuilder<InteractivePhysicsCubit, InteractivePhysicsState>(
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Error: ${state.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            physicsCubit.initializePhysics(
                                scanPath: widget.scanPath);
                          },
                          child: const Text('Try Again'),
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
                          padding: const EdgeInsets.only(bottom: 16.0),
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
                          padding: const EdgeInsets.only(bottom: 16.0),
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

              // Instructions for drag alignment
              if (!state.isLoading &&
                  state.error == null &&
                  !state.isAlignmentComplete)
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Drag anywhere on screen to move the model',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // Stats display (optional)
              if (state.showStats && !state.isLoading && state.error == null)
                Positioned(
                  top: 80,
                  right: 20,
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

  final InteractivePhysicsCubit physicsCubit;
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
  double _previousScale = 1.0;

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
                // Başlangıç ölçek faktörünü kaydet
                _previousScale = 1.0;
              },
              onScaleUpdate: (details) {
                if (details.pointerCount == 1) {
                  // Single finger drag for movement
                  if (widget.onAdjustPosition != null) {
                    widget.onAdjustPosition!(
                        details.focalPointDelta.dx, details.focalPointDelta.dy);
                  }
                } else if (details.pointerCount == 2) {
                  // İki parmak kullanıldığında
                  if (details.rotation != 0.0 &&
                      widget.onRotationUpdate != null) {
                    // Rotasyon değişimi varsa
                    final angle = details.rotation * 180 / math.pi;
                    widget.onRotationUpdate!(angle);
                  }

                  // Zoom değişimi
                  if (details.scale != 1.0 && widget.onZoomUpdate != null) {
                    // Göreceli ölçek değişimini hesapla
                    final relativeScale = details.scale / _previousScale;
                    _previousScale = details.scale;

                    // 0.95-1.05 aralığındaki küçük değişimleri filtrele
                    if (relativeScale < 0.95 || relativeScale > 1.05) {
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
    print('PhysicsARView: View created with ID $id');
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
  final Function(double, double) onAdjustPosition;
  final VoidCallback onResetAlignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Drag to move, pinch and rotate with two fingers to turn the model',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Reset button
              TextButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white),
                label:
                    const Text('Reset', style: TextStyle(color: Colors.white)),
                onPressed: onResetAlignment,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
              // Confirm alignment button
              TextButton.icon(
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text('Confirm',
                    style: TextStyle(color: Colors.white)),
                onPressed: onConfirmAlignment,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
  fine(0.01, 'Fine'),
  medium(0.05, 'Medium'),
  coarse(0.1, 'Coarse');

  const _MovementPrecisionValue(this.value, this.label);
  final double value;
  final String label;
}

// Singleton to track current precision
class _MovementPrecision {
  static _MovementPrecisionValue _precision = _MovementPrecisionValue.medium;
  static _MovementPrecisionValue get current => _precision;
  static set current(_MovementPrecisionValue value) => _precision = value;
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
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.blue.shade600;
                }
                return Colors.grey.shade800;
              },
            ),
            foregroundColor: MaterialStateProperty.all(Colors.white),
          ),
        ),
      ],
    );
  }
}

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.blue.withOpacity(0.5),
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}

class _ObjectControls extends StatefulWidget {
  const _ObjectControls({
    required this.onClearObjects,
    required this.physicsCubit,
  });

  final VoidCallback onClearObjects;
  final InteractivePhysicsCubit physicsCubit;

  @override
  State<_ObjectControls> createState() => _ObjectControlsState();
}

class _ObjectControlsState extends State<_ObjectControls> {
  // Track if mesh is visible - default false means mesh is hidden
  bool _isMeshVisible = false;
  // Current selected object type
  String _selectedObjectType = 'sphere';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Object type selector
          _buildObjectSelector(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Drop objects button
              TextButton.icon(
                icon: const Icon(Icons.cloud_download,
                    color: Colors.white, size: 24),
                label: Text(
                  'Rain $_selectedObjectType'.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  widget.physicsCubit.startObjectRain(
                    type: _selectedObjectType,
                    count: 30, // Daha fazla obje yağdıralım
                    height: 2.5, // Biraz daha yüksekten
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green.shade700.withOpacity(0.8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Hide/Show mesh button
              TextButton.icon(
                icon: Icon(
                  _isMeshVisible ? Icons.grid_off : Icons.grid_on,
                  color: Colors.white,
                ),
                label: Text(
                  _isMeshVisible ? 'Hide Mesh' : 'Show Mesh',
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  // Toggle mesh visibility state
                  setState(() {
                    _isMeshVisible = !_isMeshVisible;
                  });

                  // _isMeshVisible=true  → show the mesh (opaque)
                  // _isMeshVisible=false → hide the mesh (invisible but maintains physics)
                  widget.physicsCubit.toggleMeshVisibility(_isMeshVisible);

                  print(
                      "Mesh visibility toggled: ${_isMeshVisible ? 'VISIBLE' : 'HIDDEN'}");
                },
                style: TextButton.styleFrom(
                  backgroundColor: _isMeshVisible
                      ? Colors.orange.withOpacity(0.6)
                      : Colors.blue.withOpacity(0.6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.delete_sweep, color: Colors.white),
                label: const Text('Clear All',
                    style: TextStyle(color: Colors.white)),
                onPressed: widget.onClearObjects,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObjectSelector() {
    return Container(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _objectOption('sphere', 'Sphere', Icons.circle),
          _objectOption('cube', 'Cube', Icons.crop_square_sharp),
          _objectOption('cylinder', 'Cylinder', Icons.crop_portrait),
          _objectOption('coin', 'Coin', Icons.monetization_on),
          _objectOption('usdz', '1 Dollar', Icons.view_in_ar),
        ],
      ),
    );
  }

  Widget _objectOption(String type, String label, IconData icon) {
    final isSelected = _selectedObjectType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedObjectType = type;
        });

        // Send the selection to iOS
        widget.physicsCubit.setSelectedObjectType(type);
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
