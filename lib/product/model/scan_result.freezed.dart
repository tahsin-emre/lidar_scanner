// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scan_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ScanResult {
  double get progress => throw _privateConstructorUsedError;
  bool get isComplete => throw _privateConstructorUsedError;
  List<ScanArea> get missingAreas => throw _privateConstructorUsedError;

  /// Create a copy of ScanResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScanResultCopyWith<ScanResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScanResultCopyWith<$Res> {
  factory $ScanResultCopyWith(
          ScanResult value, $Res Function(ScanResult) then) =
      _$ScanResultCopyWithImpl<$Res, ScanResult>;
  @useResult
  $Res call({double progress, bool isComplete, List<ScanArea> missingAreas});
}

/// @nodoc
class _$ScanResultCopyWithImpl<$Res, $Val extends ScanResult>
    implements $ScanResultCopyWith<$Res> {
  _$ScanResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScanResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? progress = null,
    Object? isComplete = null,
    Object? missingAreas = null,
  }) {
    return _then(_value.copyWith(
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
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
abstract class _$$ScanResultImplCopyWith<$Res>
    implements $ScanResultCopyWith<$Res> {
  factory _$$ScanResultImplCopyWith(
          _$ScanResultImpl value, $Res Function(_$ScanResultImpl) then) =
      __$$ScanResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double progress, bool isComplete, List<ScanArea> missingAreas});
}

/// @nodoc
class __$$ScanResultImplCopyWithImpl<$Res>
    extends _$ScanResultCopyWithImpl<$Res, _$ScanResultImpl>
    implements _$$ScanResultImplCopyWith<$Res> {
  __$$ScanResultImplCopyWithImpl(
      _$ScanResultImpl _value, $Res Function(_$ScanResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScanResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? progress = null,
    Object? isComplete = null,
    Object? missingAreas = null,
  }) {
    return _then(_$ScanResultImpl(
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
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

class _$ScanResultImpl implements _ScanResult {
  const _$ScanResultImpl(
      {required this.progress,
      required this.isComplete,
      required final List<ScanArea> missingAreas})
      : _missingAreas = missingAreas;

  @override
  final double progress;
  @override
  final bool isComplete;
  final List<ScanArea> _missingAreas;
  @override
  List<ScanArea> get missingAreas {
    if (_missingAreas is EqualUnmodifiableListView) return _missingAreas;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_missingAreas);
  }

  @override
  String toString() {
    return 'ScanResult(progress: $progress, isComplete: $isComplete, missingAreas: $missingAreas)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScanResultImpl &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.isComplete, isComplete) ||
                other.isComplete == isComplete) &&
            const DeepCollectionEquality()
                .equals(other._missingAreas, _missingAreas));
  }

  @override
  int get hashCode => Object.hash(runtimeType, progress, isComplete,
      const DeepCollectionEquality().hash(_missingAreas));

  /// Create a copy of ScanResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScanResultImplCopyWith<_$ScanResultImpl> get copyWith =>
      __$$ScanResultImplCopyWithImpl<_$ScanResultImpl>(this, _$identity);
}

abstract class _ScanResult implements ScanResult {
  const factory _ScanResult(
      {required final double progress,
      required final bool isComplete,
      required final List<ScanArea> missingAreas}) = _$ScanResultImpl;

  @override
  double get progress;
  @override
  bool get isComplete;
  @override
  List<ScanArea> get missingAreas;

  /// Create a copy of ScanResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScanResultImplCopyWith<_$ScanResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ScanArea {
  double get x => throw _privateConstructorUsedError;
  double get y => throw _privateConstructorUsedError;
  double get width => throw _privateConstructorUsedError;
  double get height => throw _privateConstructorUsedError;

  /// Create a copy of ScanArea
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScanAreaCopyWith<ScanArea> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScanAreaCopyWith<$Res> {
  factory $ScanAreaCopyWith(ScanArea value, $Res Function(ScanArea) then) =
      _$ScanAreaCopyWithImpl<$Res, ScanArea>;
  @useResult
  $Res call({double x, double y, double width, double height});
}

/// @nodoc
class _$ScanAreaCopyWithImpl<$Res, $Val extends ScanArea>
    implements $ScanAreaCopyWith<$Res> {
  _$ScanAreaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScanArea
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_value.copyWith(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScanAreaImplCopyWith<$Res>
    implements $ScanAreaCopyWith<$Res> {
  factory _$$ScanAreaImplCopyWith(
          _$ScanAreaImpl value, $Res Function(_$ScanAreaImpl) then) =
      __$$ScanAreaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double x, double y, double width, double height});
}

/// @nodoc
class __$$ScanAreaImplCopyWithImpl<$Res>
    extends _$ScanAreaCopyWithImpl<$Res, _$ScanAreaImpl>
    implements _$$ScanAreaImplCopyWith<$Res> {
  __$$ScanAreaImplCopyWithImpl(
      _$ScanAreaImpl _value, $Res Function(_$ScanAreaImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScanArea
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_$ScanAreaImpl(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$ScanAreaImpl implements _ScanArea {
  const _$ScanAreaImpl(
      {required this.x,
      required this.y,
      required this.width,
      required this.height});

  @override
  final double x;
  @override
  final double y;
  @override
  final double width;
  @override
  final double height;

  @override
  String toString() {
    return 'ScanArea(x: $x, y: $y, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScanAreaImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height));
  }

  @override
  int get hashCode => Object.hash(runtimeType, x, y, width, height);

  /// Create a copy of ScanArea
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScanAreaImplCopyWith<_$ScanAreaImpl> get copyWith =>
      __$$ScanAreaImplCopyWithImpl<_$ScanAreaImpl>(this, _$identity);
}

abstract class _ScanArea implements ScanArea {
  const factory _ScanArea(
      {required final double x,
      required final double y,
      required final double width,
      required final double height}) = _$ScanAreaImpl;

  @override
  double get x;
  @override
  double get y;
  @override
  double get width;
  @override
  double get height;

  /// Create a copy of ScanArea
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScanAreaImplCopyWith<_$ScanAreaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
