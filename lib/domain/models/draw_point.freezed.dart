// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'draw_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DrawPoint _$DrawPointFromJson(Map<String, dynamic> json) {
  return _DrawPoint.fromJson(json);
}

/// @nodoc
mixin _$DrawPoint {
  double get x => throw _privateConstructorUsedError; // Posición X en el canvas
  double get y => throw _privateConstructorUsedError; // Posición Y en el canvas
  int get timestamp => throw _privateConstructorUsedError;

  /// Serializes this DrawPoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DrawPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DrawPointCopyWith<DrawPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DrawPointCopyWith<$Res> {
  factory $DrawPointCopyWith(DrawPoint value, $Res Function(DrawPoint) then) =
      _$DrawPointCopyWithImpl<$Res, DrawPoint>;
  @useResult
  $Res call({double x, double y, int timestamp});
}

/// @nodoc
class _$DrawPointCopyWithImpl<$Res, $Val extends DrawPoint>
    implements $DrawPointCopyWith<$Res> {
  _$DrawPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DrawPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? x = null, Object? y = null, Object? timestamp = null}) {
    return _then(
      _value.copyWith(
            x: null == x
                ? _value.x
                : x // ignore: cast_nullable_to_non_nullable
                      as double,
            y: null == y
                ? _value.y
                : y // ignore: cast_nullable_to_non_nullable
                      as double,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DrawPointImplCopyWith<$Res>
    implements $DrawPointCopyWith<$Res> {
  factory _$$DrawPointImplCopyWith(
    _$DrawPointImpl value,
    $Res Function(_$DrawPointImpl) then,
  ) = __$$DrawPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double x, double y, int timestamp});
}

/// @nodoc
class __$$DrawPointImplCopyWithImpl<$Res>
    extends _$DrawPointCopyWithImpl<$Res, _$DrawPointImpl>
    implements _$$DrawPointImplCopyWith<$Res> {
  __$$DrawPointImplCopyWithImpl(
    _$DrawPointImpl _value,
    $Res Function(_$DrawPointImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DrawPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? x = null, Object? y = null, Object? timestamp = null}) {
    return _then(
      _$DrawPointImpl(
        x: null == x
            ? _value.x
            : x // ignore: cast_nullable_to_non_nullable
                  as double,
        y: null == y
            ? _value.y
            : y // ignore: cast_nullable_to_non_nullable
                  as double,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DrawPointImpl implements _DrawPoint {
  const _$DrawPointImpl({
    required this.x,
    required this.y,
    required this.timestamp,
  });

  factory _$DrawPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$DrawPointImplFromJson(json);

  @override
  final double x;
  // Posición X en el canvas
  @override
  final double y;
  // Posición Y en el canvas
  @override
  final int timestamp;

  @override
  String toString() {
    return 'DrawPoint(x: $x, y: $y, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DrawPointImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, x, y, timestamp);

  /// Create a copy of DrawPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DrawPointImplCopyWith<_$DrawPointImpl> get copyWith =>
      __$$DrawPointImplCopyWithImpl<_$DrawPointImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DrawPointImplToJson(this);
  }
}

abstract class _DrawPoint implements DrawPoint {
  const factory _DrawPoint({
    required final double x,
    required final double y,
    required final int timestamp,
  }) = _$DrawPointImpl;

  factory _DrawPoint.fromJson(Map<String, dynamic> json) =
      _$DrawPointImpl.fromJson;

  @override
  double get x; // Posición X en el canvas
  @override
  double get y; // Posición Y en el canvas
  @override
  int get timestamp;

  /// Create a copy of DrawPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DrawPointImplCopyWith<_$DrawPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
