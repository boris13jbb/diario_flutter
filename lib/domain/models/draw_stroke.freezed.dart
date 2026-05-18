// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'draw_stroke.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DrawStroke _$DrawStrokeFromJson(Map<String, dynamic> json) {
  return _DrawStroke.fromJson(json);
}

/// @nodoc
mixin _$DrawStroke {
  String get id => throw _privateConstructorUsedError;
  List<DrawPoint> get points =>
      throw _privateConstructorUsedError; // Lista de puntos que forman el trazo
  int get color =>
      throw _privateConstructorUsedError; // Color del trazo (ARGB como entero)
  double get strokeWidth =>
      throw _privateConstructorUsedError; // Grosor del trazo
  int get startTimestamp => throw _privateConstructorUsedError;

  /// Serializes this DrawStroke to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DrawStroke
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DrawStrokeCopyWith<DrawStroke> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DrawStrokeCopyWith<$Res> {
  factory $DrawStrokeCopyWith(
    DrawStroke value,
    $Res Function(DrawStroke) then,
  ) = _$DrawStrokeCopyWithImpl<$Res, DrawStroke>;
  @useResult
  $Res call({
    String id,
    List<DrawPoint> points,
    int color,
    double strokeWidth,
    int startTimestamp,
  });
}

/// @nodoc
class _$DrawStrokeCopyWithImpl<$Res, $Val extends DrawStroke>
    implements $DrawStrokeCopyWith<$Res> {
  _$DrawStrokeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DrawStroke
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? points = null,
    Object? color = null,
    Object? strokeWidth = null,
    Object? startTimestamp = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            points: null == points
                ? _value.points
                : points // ignore: cast_nullable_to_non_nullable
                      as List<DrawPoint>,
            color: null == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as int,
            strokeWidth: null == strokeWidth
                ? _value.strokeWidth
                : strokeWidth // ignore: cast_nullable_to_non_nullable
                      as double,
            startTimestamp: null == startTimestamp
                ? _value.startTimestamp
                : startTimestamp // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DrawStrokeImplCopyWith<$Res>
    implements $DrawStrokeCopyWith<$Res> {
  factory _$$DrawStrokeImplCopyWith(
    _$DrawStrokeImpl value,
    $Res Function(_$DrawStrokeImpl) then,
  ) = __$$DrawStrokeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    List<DrawPoint> points,
    int color,
    double strokeWidth,
    int startTimestamp,
  });
}

/// @nodoc
class __$$DrawStrokeImplCopyWithImpl<$Res>
    extends _$DrawStrokeCopyWithImpl<$Res, _$DrawStrokeImpl>
    implements _$$DrawStrokeImplCopyWith<$Res> {
  __$$DrawStrokeImplCopyWithImpl(
    _$DrawStrokeImpl _value,
    $Res Function(_$DrawStrokeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DrawStroke
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? points = null,
    Object? color = null,
    Object? strokeWidth = null,
    Object? startTimestamp = null,
  }) {
    return _then(
      _$DrawStrokeImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        points: null == points
            ? _value._points
            : points // ignore: cast_nullable_to_non_nullable
                  as List<DrawPoint>,
        color: null == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as int,
        strokeWidth: null == strokeWidth
            ? _value.strokeWidth
            : strokeWidth // ignore: cast_nullable_to_non_nullable
                  as double,
        startTimestamp: null == startTimestamp
            ? _value.startTimestamp
            : startTimestamp // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DrawStrokeImpl implements _DrawStroke {
  const _$DrawStrokeImpl({
    required this.id,
    required final List<DrawPoint> points,
    required this.color,
    this.strokeWidth = 2.0,
    required this.startTimestamp,
  }) : _points = points;

  factory _$DrawStrokeImpl.fromJson(Map<String, dynamic> json) =>
      _$$DrawStrokeImplFromJson(json);

  @override
  final String id;
  final List<DrawPoint> _points;
  @override
  List<DrawPoint> get points {
    if (_points is EqualUnmodifiableListView) return _points;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_points);
  }

  // Lista de puntos que forman el trazo
  @override
  final int color;
  // Color del trazo (ARGB como entero)
  @override
  @JsonKey()
  final double strokeWidth;
  // Grosor del trazo
  @override
  final int startTimestamp;

  @override
  String toString() {
    return 'DrawStroke(id: $id, points: $points, color: $color, strokeWidth: $strokeWidth, startTimestamp: $startTimestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DrawStrokeImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._points, _points) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.strokeWidth, strokeWidth) ||
                other.strokeWidth == strokeWidth) &&
            (identical(other.startTimestamp, startTimestamp) ||
                other.startTimestamp == startTimestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    const DeepCollectionEquality().hash(_points),
    color,
    strokeWidth,
    startTimestamp,
  );

  /// Create a copy of DrawStroke
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DrawStrokeImplCopyWith<_$DrawStrokeImpl> get copyWith =>
      __$$DrawStrokeImplCopyWithImpl<_$DrawStrokeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DrawStrokeImplToJson(this);
  }
}

abstract class _DrawStroke implements DrawStroke {
  const factory _DrawStroke({
    required final String id,
    required final List<DrawPoint> points,
    required final int color,
    final double strokeWidth,
    required final int startTimestamp,
  }) = _$DrawStrokeImpl;

  factory _DrawStroke.fromJson(Map<String, dynamic> json) =
      _$DrawStrokeImpl.fromJson;

  @override
  String get id;
  @override
  List<DrawPoint> get points; // Lista de puntos que forman el trazo
  @override
  int get color; // Color del trazo (ARGB como entero)
  @override
  double get strokeWidth; // Grosor del trazo
  @override
  int get startTimestamp;

  /// Create a copy of DrawStroke
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DrawStrokeImplCopyWith<_$DrawStrokeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
