import 'package:equatable/equatable.dart';
import 'package:lidar_scanner/product/model/physics_object.dart';

/// Represents the state of the interactive physics simulation
class InteractivePhysicsState extends Equatable {
  const InteractivePhysicsState({
    this.isLoading = false,
    this.error,
    this.objects = const [],
    this.selectedObjectType = PhysicsObjectType.sphere,
    this.fps = 0.0,
    this.showStats = true,
    this.isSimulationRunning = false,
    this.isAlignmentComplete = false,
    this.modelOffsetX = 0.0,
    this.modelOffsetY = 0.0,
  });

  /// Whether the physics environment is loading
  final bool isLoading;

  /// Error message if loading failed
  final String? error;

  /// List of physics objects in the simulation
  final List<PhysicsObject> objects;

  /// Currently selected object type to place
  final PhysicsObjectType selectedObjectType;

  /// Current frames per second of the simulation
  final double fps;

  /// Whether to show performance stats
  final bool showStats;

  /// Whether the physics simulation is currently running
  final bool isSimulationRunning;

  /// Whether the model alignment phase is complete
  final bool isAlignmentComplete;

  /// X-axis offset for model alignment
  final double modelOffsetX;

  /// Y-axis offset for model alignment
  final double modelOffsetY;

  /// Create a copy with updated properties
  InteractivePhysicsState copyWith({
    bool? isLoading,
    String? error,
    List<PhysicsObject>? objects,
    PhysicsObjectType? selectedObjectType,
    double? fps,
    bool? showStats,
    bool? isSimulationRunning,
    bool? isAlignmentComplete,
    double? modelOffsetX,
    double? modelOffsetY,
  }) {
    return InteractivePhysicsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      objects: objects ?? this.objects,
      selectedObjectType: selectedObjectType ?? this.selectedObjectType,
      fps: fps ?? this.fps,
      showStats: showStats ?? this.showStats,
      isSimulationRunning: isSimulationRunning ?? this.isSimulationRunning,
      isAlignmentComplete: isAlignmentComplete ?? this.isAlignmentComplete,
      modelOffsetX: modelOffsetX ?? this.modelOffsetX,
      modelOffsetY: modelOffsetY ?? this.modelOffsetY,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        objects,
        selectedObjectType,
        fps,
        showStats,
        isSimulationRunning,
        isAlignmentComplete,
        modelOffsetX,
        modelOffsetY,
      ];
}
