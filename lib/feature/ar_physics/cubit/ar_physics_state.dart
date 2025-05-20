import 'package:equatable/equatable.dart';
import 'package:lidar_scanner/product/model/physics_object.dart';

/// AR Fizik modülü durumu
class ARPhysicsState extends Equatable {
  /// Yeni bir AR Fizik durumu oluştur
  const ARPhysicsState({
    this.isInitialized = false,
    this.objects = const [],
    this.selectedObjectType = PhysicsObjectType.sphere,
    this.error = '',
    this.fps = 0,
  });

  /// AR görünümünün başlatılıp başlatılmadığı
  final bool isInitialized;

  /// AR görünümünde bulunan fizik objeleri
  final List<PhysicsObject> objects;

  /// Şu anda seçili olan obje tipi
  final PhysicsObjectType selectedObjectType;

  /// Hata mesajı (varsa)
  final String error;

  /// Mevcut FPS değeri
  final double fps;

  /// Yeni bir durum oluştur
  ARPhysicsState copyWith({
    bool? isInitialized,
    List<PhysicsObject>? objects,
    PhysicsObjectType? selectedObjectType,
    String? error,
    double? fps,
  }) {
    return ARPhysicsState(
      isInitialized: isInitialized ?? this.isInitialized,
      objects: objects ?? this.objects,
      selectedObjectType: selectedObjectType ?? this.selectedObjectType,
      error: error ?? this.error,
      fps: fps ?? this.fps,
    );
  }

  @override
  List<Object?> get props => [
        isInitialized,
        objects,
        selectedObjectType,
        error,
        fps,
      ];
}
