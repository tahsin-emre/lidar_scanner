// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scanner_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ScannerState {
  bool get canScan => throw _privateConstructorUsedError;
  bool get isScanning => throw _privateConstructorUsedError;
  double get scanProgress => throw _privateConstructorUsedError;
  bool get isComplete => throw _privateConstructorUsedError;
  List<ScanArea> get missingAreas => throw _privateConstructorUsedError;

  /// Create a copy of ScannerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScannerStateCopyWith<ScannerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScannerStateCopyWith<$Res> {
  factory $ScannerStateCopyWith(
          ScannerState value, $Res Function(ScannerState) then) =
      _$ScannerStateCopyWithImpl<$Res, ScannerState>;
  @useResult
  $Res call(
      {bool canScan,
      bool isScanning,
      double scanProgress,
      bool isComplete,
      List<ScanArea> missingAreas});
}

/// @nodoc
class _$ScannerStateCopyWithImpl<$Res, $Val extends ScannerState>
    implements $ScannerStateCopyWith<$Res> {
  _$ScannerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScannerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? canScan = null,
    Object? isScanning = null,
    Object? scanProgress = null,
    Object? isComplete = null,
    Object? missingAreas = null,
  }) {
    return _then(_value.copyWith(
      canScan: null == canScan
          ? _value.canScan
          : canScan // ignore: cast_nullable_to_non_nullable
              as bool,
      isScanning: null == isScanning
          ? _value.isScanning
          : isScanning // ignore: cast_nullable_to_non_nullable
              as bool,
      scanProgress: null == scanProgress
          ? _value.scanProgress
          : scanProgress // ignore: cast_nullable_to_non_nullable
              as double,
      isComplete: null == isComplete
          ? _value.isComplete
          : isComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      missingAreas: null == missingAreas
          ? _value.missingAreas
          : missingAreas // ignore: cast_nullable_to_non_nullable
              as List<ScanArea>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScannerStateImplCopyWith<$Res>
    implements $ScannerStateCopyWith<$Res> {
  factory _$$ScannerStateImplCopyWith(
          _$ScannerStateImpl value, $Res Function(_$ScannerStateImpl) then) =
      __$$ScannerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool canScan,
      bool isScanning,
      double scanProgress,
      bool isComplete,
      List<ScanArea> missingAreas});
}

/// @nodoc
class __$$ScannerStateImplCopyWithImpl<$Res>
    extends _$ScannerStateCopyWithImpl<$Res, _$ScannerStateImpl>
    implements _$$ScannerStateImplCopyWith<$Res> {
  __$$ScannerStateImplCopyWithImpl(
      _$ScannerStateImpl _value, $Res Function(_$ScannerStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScannerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? canScan = null,
    Object? isScanning = null,
    Object? scanProgress = null,
    Object? isComplete = null,
    Object? missingAreas = null,
  }) {
    return _then(_$ScannerStateImpl(
      canScan: null == canScan
          ? _value.canScan
          : canScan // ignore: cast_nullable_to_non_nullable
              as bool,
      isScanning: null == isScanning
          ? _value.isScanning
          : isScanning // ignore: cast_nullable_to_non_nullable
              as bool,
      scanProgress: null == scanProgress
          ? _value.scanProgress
          : scanProgress // ignore: cast_nullable_to_non_nullable
              as double,
      isComplete: null == isComplete
          ? _value.isComplete
          : isComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      missingAreas: null == missingAreas
          ? _value._missingAreas
          : missingAreas // ignore: cast_nullable_to_non_nullable
              as List<ScanArea>,
    ));
  }
}

/// @nodoc

class _$ScannerStateImpl implements _ScannerState {
  const _$ScannerStateImpl(
      {required this.canScan,
      required this.isScanning,
      this.scanProgress = 0.0,
      this.isComplete = false,
      final List<ScanArea> missingAreas = const []})
      : _missingAreas = missingAreas;

  @override
  final bool canScan;
  @override
  final bool isScanning;
  @override
  @JsonKey()
  final double scanProgress;
  @override
  @JsonKey()
  final bool isComplete;
  final List<ScanArea> _missingAreas;
  @override
  @JsonKey()
  List<ScanArea> get missingAreas {
    if (_missingAreas is EqualUnmodifiableListView) return _missingAreas;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_missingAreas);
  }

  @override
  String toString() {
    return 'ScannerState(canScan: $canScan, isScanning: $isScanning, scanProgress: $scanProgress, isComplete: $isComplete, missingAreas: $missingAreas)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScannerStateImpl &&
            (identical(other.canScan, canScan) || other.canScan == canScan) &&
            (identical(other.isScanning, isScanning) ||
                other.isScanning == isScanning) &&
            (identical(other.scanProgress, scanProgress) ||
                other.scanProgress == scanProgress) &&
            (identical(other.isComplete, isComplete) ||
                other.isComplete == isComplete) &&
            const DeepCollectionEquality()
                .equals(other._missingAreas, _missingAreas));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      canScan,
      isScanning,
      scanProgress,
      isComplete,
      const DeepCollectionEquality().hash(_missingAreas));

  /// Create a copy of ScannerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScannerStateImplCopyWith<_$ScannerStateImpl> get copyWith =>
      __$$ScannerStateImplCopyWithImpl<_$ScannerStateImpl>(this, _$identity);
}

abstract class _ScannerState implements ScannerState {
  const factory _ScannerState(
      {required final bool canScan,
      required final bool isScanning,
      final double scanProgress,
      final bool isComplete,
      final List<ScanArea> missingAreas}) = _$ScannerStateImpl;

  @override
  bool get canScan;
  @override
  bool get isScanning;
  @override
  double get scanProgress;
  @override
  bool get isComplete;
  @override
  List<ScanArea> get missingAreas;

  /// Create a copy of ScannerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScannerStateImplCopyWith<_$ScannerStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
