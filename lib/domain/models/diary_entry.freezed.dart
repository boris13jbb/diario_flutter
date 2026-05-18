// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diary_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DiaryEntry _$DiaryEntryFromJson(Map<String, dynamic> json) {
  return _DiaryEntry.fromJson(json);
}

/// @nodoc
mixin _$DiaryEntry {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError; // ID del usuario propietario
  String get date => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  @JsonKey(name: 'audio_markers', defaultValue: [])
  List<AudioMarker> get audioMarkers => throw _privateConstructorUsedError; // Marcadores de audio
  @JsonKey(name: 'draw_strokes', defaultValue: [])
  List<DrawStroke> get drawStrokes => throw _privateConstructorUsedError; // Trazos de dibujo
  @JsonKey(name: 'audio_file_path')
  String? get audioFilePath => throw _privateConstructorUsedError; // Ruta al archivo de audio grabado
  bool get synced =>
      throw _privateConstructorUsedError; // Estado de sincronización con Supabase
  @JsonKey(name: 'last_updated')
  int get lastUpdated => throw _privateConstructorUsedError; // Timestamp de última actualización
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this DiaryEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DiaryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiaryEntryCopyWith<DiaryEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiaryEntryCopyWith<$Res> {
  factory $DiaryEntryCopyWith(
    DiaryEntry value,
    $Res Function(DiaryEntry) then,
  ) = _$DiaryEntryCopyWithImpl<$Res, DiaryEntry>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    String date,
    String title,
    String content,
    @JsonKey(name: 'audio_markers', defaultValue: [])
    List<AudioMarker> audioMarkers,
    @JsonKey(name: 'draw_strokes', defaultValue: [])
    List<DrawStroke> drawStrokes,
    @JsonKey(name: 'audio_file_path') String? audioFilePath,
    bool synced,
    @JsonKey(name: 'last_updated') int lastUpdated,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$DiaryEntryCopyWithImpl<$Res, $Val extends DiaryEntry>
    implements $DiaryEntryCopyWith<$Res> {
  _$DiaryEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiaryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? date = null,
    Object? title = null,
    Object? content = null,
    Object? audioMarkers = null,
    Object? drawStrokes = null,
    Object? audioFilePath = freezed,
    Object? synced = null,
    Object? lastUpdated = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            audioMarkers: null == audioMarkers
                ? _value.audioMarkers
                : audioMarkers // ignore: cast_nullable_to_non_nullable
                      as List<AudioMarker>,
            drawStrokes: null == drawStrokes
                ? _value.drawStrokes
                : drawStrokes // ignore: cast_nullable_to_non_nullable
                      as List<DrawStroke>,
            audioFilePath: freezed == audioFilePath
                ? _value.audioFilePath
                : audioFilePath // ignore: cast_nullable_to_non_nullable
                      as String?,
            synced: null == synced
                ? _value.synced
                : synced // ignore: cast_nullable_to_non_nullable
                      as bool,
            lastUpdated: null == lastUpdated
                ? _value.lastUpdated
                : lastUpdated // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DiaryEntryImplCopyWith<$Res>
    implements $DiaryEntryCopyWith<$Res> {
  factory _$$DiaryEntryImplCopyWith(
    _$DiaryEntryImpl value,
    $Res Function(_$DiaryEntryImpl) then,
  ) = __$$DiaryEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    String date,
    String title,
    String content,
    @JsonKey(name: 'audio_markers', defaultValue: [])
    List<AudioMarker> audioMarkers,
    @JsonKey(name: 'draw_strokes', defaultValue: [])
    List<DrawStroke> drawStrokes,
    @JsonKey(name: 'audio_file_path') String? audioFilePath,
    bool synced,
    @JsonKey(name: 'last_updated') int lastUpdated,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$DiaryEntryImplCopyWithImpl<$Res>
    extends _$DiaryEntryCopyWithImpl<$Res, _$DiaryEntryImpl>
    implements _$$DiaryEntryImplCopyWith<$Res> {
  __$$DiaryEntryImplCopyWithImpl(
    _$DiaryEntryImpl _value,
    $Res Function(_$DiaryEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DiaryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? date = null,
    Object? title = null,
    Object? content = null,
    Object? audioMarkers = null,
    Object? drawStrokes = null,
    Object? audioFilePath = freezed,
    Object? synced = null,
    Object? lastUpdated = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$DiaryEntryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        audioMarkers: null == audioMarkers
            ? _value._audioMarkers
            : audioMarkers // ignore: cast_nullable_to_non_nullable
                  as List<AudioMarker>,
        drawStrokes: null == drawStrokes
            ? _value._drawStrokes
            : drawStrokes // ignore: cast_nullable_to_non_nullable
                  as List<DrawStroke>,
        audioFilePath: freezed == audioFilePath
            ? _value.audioFilePath
            : audioFilePath // ignore: cast_nullable_to_non_nullable
                  as String?,
        synced: null == synced
            ? _value.synced
            : synced // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastUpdated: null == lastUpdated
            ? _value.lastUpdated
            : lastUpdated // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DiaryEntryImpl implements _DiaryEntry {
  const _$DiaryEntryImpl({
    required this.id,
    @JsonKey(name: 'user_id') required this.userId,
    required this.date,
    required this.title,
    required this.content,
    @JsonKey(name: 'audio_markers', defaultValue: [])
    final List<AudioMarker> audioMarkers = const [],
    @JsonKey(name: 'draw_strokes', defaultValue: [])
    final List<DrawStroke> drawStrokes = const [],
    @JsonKey(name: 'audio_file_path') this.audioFilePath,
    this.synced = false,
    @JsonKey(name: 'last_updated') required this.lastUpdated,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  }) : _audioMarkers = audioMarkers,
       _drawStrokes = drawStrokes;

  factory _$DiaryEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiaryEntryImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  // ID del usuario propietario
  @override
  final String date;
  @override
  final String title;
  @override
  final String content;
  final List<AudioMarker> _audioMarkers;
  @override
  @JsonKey(name: 'audio_markers', defaultValue: [])
  List<AudioMarker> get audioMarkers {
    if (_audioMarkers is EqualUnmodifiableListView) return _audioMarkers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_audioMarkers);
  }

  // Marcadores de audio
  final List<DrawStroke> _drawStrokes;
  // Marcadores de audio
  @override
  @JsonKey(name: 'draw_strokes', defaultValue: [])
  List<DrawStroke> get drawStrokes {
    if (_drawStrokes is EqualUnmodifiableListView) return _drawStrokes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_drawStrokes);
  }

  // Trazos de dibujo
  @override
  @JsonKey(name: 'audio_file_path')
  final String? audioFilePath;
  // Ruta al archivo de audio grabado
  @override
  @JsonKey()
  final bool synced;
  // Estado de sincronización con Supabase
  @override
  @JsonKey(name: 'last_updated')
  final int lastUpdated;
  // Timestamp de última actualización
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'DiaryEntry(id: $id, userId: $userId, date: $date, title: $title, content: $content, audioMarkers: $audioMarkers, drawStrokes: $drawStrokes, audioFilePath: $audioFilePath, synced: $synced, lastUpdated: $lastUpdated, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiaryEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality().equals(
              other._audioMarkers,
              _audioMarkers,
            ) &&
            const DeepCollectionEquality().equals(
              other._drawStrokes,
              _drawStrokes,
            ) &&
            (identical(other.audioFilePath, audioFilePath) ||
                other.audioFilePath == audioFilePath) &&
            (identical(other.synced, synced) || other.synced == synced) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    date,
    title,
    content,
    const DeepCollectionEquality().hash(_audioMarkers),
    const DeepCollectionEquality().hash(_drawStrokes),
    audioFilePath,
    synced,
    lastUpdated,
    createdAt,
    updatedAt,
  );

  /// Create a copy of DiaryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiaryEntryImplCopyWith<_$DiaryEntryImpl> get copyWith =>
      __$$DiaryEntryImplCopyWithImpl<_$DiaryEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiaryEntryImplToJson(this);
  }
}

abstract class _DiaryEntry implements DiaryEntry {
  const factory _DiaryEntry({
    required final String id,
    @JsonKey(name: 'user_id') required final String userId,
    required final String date,
    required final String title,
    required final String content,
    @JsonKey(name: 'audio_markers', defaultValue: [])
    final List<AudioMarker> audioMarkers,
    @JsonKey(name: 'draw_strokes', defaultValue: [])
    final List<DrawStroke> drawStrokes,
    @JsonKey(name: 'audio_file_path') final String? audioFilePath,
    final bool synced,
    @JsonKey(name: 'last_updated') required final int lastUpdated,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$DiaryEntryImpl;

  factory _DiaryEntry.fromJson(Map<String, dynamic> json) =
      _$DiaryEntryImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId; // ID del usuario propietario
  @override
  String get date;
  @override
  String get title;
  @override
  String get content;
  @override
  @JsonKey(name: 'audio_markers', defaultValue: [])
  List<AudioMarker> get audioMarkers; // Marcadores de audio
  @override
  @JsonKey(name: 'draw_strokes', defaultValue: [])
  List<DrawStroke> get drawStrokes; // Trazos de dibujo
  @override
  @JsonKey(name: 'audio_file_path')
  String? get audioFilePath; // Ruta al archivo de audio grabado
  @override
  bool get synced; // Estado de sincronización con Supabase
  @override
  @JsonKey(name: 'last_updated')
  int get lastUpdated; // Timestamp de última actualización
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of DiaryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiaryEntryImplCopyWith<_$DiaryEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
