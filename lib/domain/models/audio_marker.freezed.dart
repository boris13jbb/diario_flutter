// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_marker.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AudioMarker _$AudioMarkerFromJson(Map<String, dynamic> json) {
  return _AudioMarker.fromJson(json);
}

/// @nodoc
mixin _$AudioMarker {
  String get id => throw _privateConstructorUsedError;
  int get timestamp =>
      throw _privateConstructorUsedError; // Tiempo en milisegundos desde el inicio
  String get text => throw _privateConstructorUsedError;

  /// Serializes this AudioMarker to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AudioMarker
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AudioMarkerCopyWith<AudioMarker> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AudioMarkerCopyWith<$Res> {
  factory $AudioMarkerCopyWith(
    AudioMarker value,
    $Res Function(AudioMarker) then,
  ) = _$AudioMarkerCopyWithImpl<$Res, AudioMarker>;
  @useResult
  $Res call({String id, int timestamp, String text});
}

/// @nodoc
class _$AudioMarkerCopyWithImpl<$Res, $Val extends AudioMarker>
    implements $AudioMarkerCopyWith<$Res> {
  _$AudioMarkerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AudioMarker
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? timestamp = null,
    Object? text = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as int,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AudioMarkerImplCopyWith<$Res>
    implements $AudioMarkerCopyWith<$Res> {
  factory _$$AudioMarkerImplCopyWith(
    _$AudioMarkerImpl value,
    $Res Function(_$AudioMarkerImpl) then,
  ) = __$$AudioMarkerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, int timestamp, String text});
}

/// @nodoc
class __$$AudioMarkerImplCopyWithImpl<$Res>
    extends _$AudioMarkerCopyWithImpl<$Res, _$AudioMarkerImpl>
    implements _$$AudioMarkerImplCopyWith<$Res> {
  __$$AudioMarkerImplCopyWithImpl(
    _$AudioMarkerImpl _value,
    $Res Function(_$AudioMarkerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AudioMarker
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? timestamp = null,
    Object? text = null,
  }) {
    return _then(
      _$AudioMarkerImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as int,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AudioMarkerImpl implements _AudioMarker {
  const _$AudioMarkerImpl({
    required this.id,
    required this.timestamp,
    this.text = '',
  });

  factory _$AudioMarkerImpl.fromJson(Map<String, dynamic> json) =>
      _$$AudioMarkerImplFromJson(json);

  @override
  final String id;
  @override
  final int timestamp;
  // Tiempo en milisegundos desde el inicio
  @override
  @JsonKey()
  final String text;

  @override
  String toString() {
    return 'AudioMarker(id: $id, timestamp: $timestamp, text: $text)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AudioMarkerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.text, text) || other.text == text));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, timestamp, text);

  /// Create a copy of AudioMarker
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AudioMarkerImplCopyWith<_$AudioMarkerImpl> get copyWith =>
      __$$AudioMarkerImplCopyWithImpl<_$AudioMarkerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AudioMarkerImplToJson(this);
  }
}

abstract class _AudioMarker implements AudioMarker {
  const factory _AudioMarker({
    required final String id,
    required final int timestamp,
    final String text,
  }) = _$AudioMarkerImpl;

  factory _AudioMarker.fromJson(Map<String, dynamic> json) =
      _$AudioMarkerImpl.fromJson;

  @override
  String get id;
  @override
  int get timestamp; // Tiempo en milisegundos desde el inicio
  @override
  String get text;

  /// Create a copy of AudioMarker
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AudioMarkerImplCopyWith<_$AudioMarkerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
