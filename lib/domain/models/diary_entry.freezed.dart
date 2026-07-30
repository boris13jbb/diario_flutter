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
  String get userId => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  @JsonKey(name: 'audio_markers', defaultValue: [])
  List<AudioMarker> get audioMarkers => throw _privateConstructorUsedError;
  @JsonKey(name: 'draw_strokes', defaultValue: [])
  List<DrawStroke> get drawStrokes => throw _privateConstructorUsedError;
  @JsonKey(name: 'audio_file_path')
  String? get audioFilePath => throw _privateConstructorUsedError;
  @JsonKey(name: 'category_id')
  String? get categoryId => throw _privateConstructorUsedError;
  bool get synced => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_updated')
  int get lastUpdated => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_pinned')
  bool get isPinned => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_archived')
  bool get isArchived => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_deleted')
  bool get isDeleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'color_value')
  int? get colorValue => throw _privateConstructorUsedError;
  int get priority => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _tagsFromJson)
  List<String> get tags => throw _privateConstructorUsedError;
  @JsonKey(name: 'tasks', fromJson: _tasksFromJson, toJson: _tasksToJson)
  List<NoteTask> get tasks => throw _privateConstructorUsedError;
  @JsonKey(name: 'links', fromJson: _linksFromJson, toJson: _linksToJson)
  List<NoteLink> get links => throw _privateConstructorUsedError;
  @JsonKey(
    name: 'attachments',
    fromJson: _attachmentsFromJson,
    toJson: _attachmentsToJson,
  )
  List<NoteAttachment> get attachments => throw _privateConstructorUsedError;
  @JsonKey(name: 'reminder_at')
  DateTime? get reminderAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'lock_pin_hash')
  String? get lockPinHash => throw _privateConstructorUsedError;

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
    @JsonKey(name: 'category_id') String? categoryId,
    bool synced,
    @JsonKey(name: 'last_updated') int lastUpdated,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'is_pinned') bool isPinned,
    @JsonKey(name: 'is_archived') bool isArchived,
    @JsonKey(name: 'is_deleted') bool isDeleted,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'color_value') int? colorValue,
    int priority,
    @JsonKey(fromJson: _tagsFromJson) List<String> tags,
    @JsonKey(name: 'tasks', fromJson: _tasksFromJson, toJson: _tasksToJson)
    List<NoteTask> tasks,
    @JsonKey(name: 'links', fromJson: _linksFromJson, toJson: _linksToJson)
    List<NoteLink> links,
    @JsonKey(
      name: 'attachments',
      fromJson: _attachmentsFromJson,
      toJson: _attachmentsToJson,
    )
    List<NoteAttachment> attachments,
    @JsonKey(name: 'reminder_at') DateTime? reminderAt,
    @JsonKey(name: 'lock_pin_hash') String? lockPinHash,
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
    Object? categoryId = freezed,
    Object? synced = null,
    Object? lastUpdated = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? isPinned = null,
    Object? isArchived = null,
    Object? isDeleted = null,
    Object? deletedAt = freezed,
    Object? colorValue = freezed,
    Object? priority = null,
    Object? tags = null,
    Object? tasks = null,
    Object? links = null,
    Object? attachments = null,
    Object? reminderAt = freezed,
    Object? lockPinHash = freezed,
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
            categoryId: freezed == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
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
            isPinned: null == isPinned
                ? _value.isPinned
                : isPinned // ignore: cast_nullable_to_non_nullable
                      as bool,
            isArchived: null == isArchived
                ? _value.isArchived
                : isArchived // ignore: cast_nullable_to_non_nullable
                      as bool,
            isDeleted: null == isDeleted
                ? _value.isDeleted
                : isDeleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            deletedAt: freezed == deletedAt
                ? _value.deletedAt
                : deletedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            colorValue: freezed == colorValue
                ? _value.colorValue
                : colorValue // ignore: cast_nullable_to_non_nullable
                      as int?,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as int,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            tasks: null == tasks
                ? _value.tasks
                : tasks // ignore: cast_nullable_to_non_nullable
                      as List<NoteTask>,
            links: null == links
                ? _value.links
                : links // ignore: cast_nullable_to_non_nullable
                      as List<NoteLink>,
            attachments: null == attachments
                ? _value.attachments
                : attachments // ignore: cast_nullable_to_non_nullable
                      as List<NoteAttachment>,
            reminderAt: freezed == reminderAt
                ? _value.reminderAt
                : reminderAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lockPinHash: freezed == lockPinHash
                ? _value.lockPinHash
                : lockPinHash // ignore: cast_nullable_to_non_nullable
                      as String?,
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
    @JsonKey(name: 'category_id') String? categoryId,
    bool synced,
    @JsonKey(name: 'last_updated') int lastUpdated,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'is_pinned') bool isPinned,
    @JsonKey(name: 'is_archived') bool isArchived,
    @JsonKey(name: 'is_deleted') bool isDeleted,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'color_value') int? colorValue,
    int priority,
    @JsonKey(fromJson: _tagsFromJson) List<String> tags,
    @JsonKey(name: 'tasks', fromJson: _tasksFromJson, toJson: _tasksToJson)
    List<NoteTask> tasks,
    @JsonKey(name: 'links', fromJson: _linksFromJson, toJson: _linksToJson)
    List<NoteLink> links,
    @JsonKey(
      name: 'attachments',
      fromJson: _attachmentsFromJson,
      toJson: _attachmentsToJson,
    )
    List<NoteAttachment> attachments,
    @JsonKey(name: 'reminder_at') DateTime? reminderAt,
    @JsonKey(name: 'lock_pin_hash') String? lockPinHash,
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
    Object? categoryId = freezed,
    Object? synced = null,
    Object? lastUpdated = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? isPinned = null,
    Object? isArchived = null,
    Object? isDeleted = null,
    Object? deletedAt = freezed,
    Object? colorValue = freezed,
    Object? priority = null,
    Object? tags = null,
    Object? tasks = null,
    Object? links = null,
    Object? attachments = null,
    Object? reminderAt = freezed,
    Object? lockPinHash = freezed,
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
        categoryId: freezed == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
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
        isPinned: null == isPinned
            ? _value.isPinned
            : isPinned // ignore: cast_nullable_to_non_nullable
                  as bool,
        isArchived: null == isArchived
            ? _value.isArchived
            : isArchived // ignore: cast_nullable_to_non_nullable
                  as bool,
        isDeleted: null == isDeleted
            ? _value.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        deletedAt: freezed == deletedAt
            ? _value.deletedAt
            : deletedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        colorValue: freezed == colorValue
            ? _value.colorValue
            : colorValue // ignore: cast_nullable_to_non_nullable
                  as int?,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as int,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        tasks: null == tasks
            ? _value._tasks
            : tasks // ignore: cast_nullable_to_non_nullable
                  as List<NoteTask>,
        links: null == links
            ? _value._links
            : links // ignore: cast_nullable_to_non_nullable
                  as List<NoteLink>,
        attachments: null == attachments
            ? _value._attachments
            : attachments // ignore: cast_nullable_to_non_nullable
                  as List<NoteAttachment>,
        reminderAt: freezed == reminderAt
            ? _value.reminderAt
            : reminderAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lockPinHash: freezed == lockPinHash
            ? _value.lockPinHash
            : lockPinHash // ignore: cast_nullable_to_non_nullable
                  as String?,
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
    @JsonKey(name: 'category_id') this.categoryId,
    this.synced = false,
    @JsonKey(name: 'last_updated') required this.lastUpdated,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
    @JsonKey(name: 'is_pinned') this.isPinned = false,
    @JsonKey(name: 'is_archived') this.isArchived = false,
    @JsonKey(name: 'is_deleted') this.isDeleted = false,
    @JsonKey(name: 'deleted_at') this.deletedAt,
    @JsonKey(name: 'color_value') this.colorValue,
    this.priority = 0,
    @JsonKey(fromJson: _tagsFromJson) final List<String> tags = const [],
    @JsonKey(name: 'tasks', fromJson: _tasksFromJson, toJson: _tasksToJson)
    final List<NoteTask> tasks = const [],
    @JsonKey(name: 'links', fromJson: _linksFromJson, toJson: _linksToJson)
    final List<NoteLink> links = const [],
    @JsonKey(
      name: 'attachments',
      fromJson: _attachmentsFromJson,
      toJson: _attachmentsToJson,
    )
    final List<NoteAttachment> attachments = const [],
    @JsonKey(name: 'reminder_at') this.reminderAt,
    @JsonKey(name: 'lock_pin_hash') this.lockPinHash,
  }) : _audioMarkers = audioMarkers,
       _drawStrokes = drawStrokes,
       _tags = tags,
       _tasks = tasks,
       _links = links,
       _attachments = attachments;

  factory _$DiaryEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiaryEntryImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
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

  final List<DrawStroke> _drawStrokes;
  @override
  @JsonKey(name: 'draw_strokes', defaultValue: [])
  List<DrawStroke> get drawStrokes {
    if (_drawStrokes is EqualUnmodifiableListView) return _drawStrokes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_drawStrokes);
  }

  @override
  @JsonKey(name: 'audio_file_path')
  final String? audioFilePath;
  @override
  @JsonKey(name: 'category_id')
  final String? categoryId;
  @override
  @JsonKey()
  final bool synced;
  @override
  @JsonKey(name: 'last_updated')
  final int lastUpdated;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey(name: 'is_pinned')
  final bool isPinned;
  @override
  @JsonKey(name: 'is_archived')
  final bool isArchived;
  @override
  @JsonKey(name: 'is_deleted')
  final bool isDeleted;
  @override
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;
  @override
  @JsonKey(name: 'color_value')
  final int? colorValue;
  @override
  @JsonKey()
  final int priority;
  final List<String> _tags;
  @override
  @JsonKey(fromJson: _tagsFromJson)
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final List<NoteTask> _tasks;
  @override
  @JsonKey(name: 'tasks', fromJson: _tasksFromJson, toJson: _tasksToJson)
  List<NoteTask> get tasks {
    if (_tasks is EqualUnmodifiableListView) return _tasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tasks);
  }

  final List<NoteLink> _links;
  @override
  @JsonKey(name: 'links', fromJson: _linksFromJson, toJson: _linksToJson)
  List<NoteLink> get links {
    if (_links is EqualUnmodifiableListView) return _links;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_links);
  }

  final List<NoteAttachment> _attachments;
  @override
  @JsonKey(
    name: 'attachments',
    fromJson: _attachmentsFromJson,
    toJson: _attachmentsToJson,
  )
  List<NoteAttachment> get attachments {
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachments);
  }

  @override
  @JsonKey(name: 'reminder_at')
  final DateTime? reminderAt;
  @override
  @JsonKey(name: 'lock_pin_hash')
  final String? lockPinHash;

  @override
  String toString() {
    return 'DiaryEntry(id: $id, userId: $userId, date: $date, title: $title, content: $content, audioMarkers: $audioMarkers, drawStrokes: $drawStrokes, audioFilePath: $audioFilePath, categoryId: $categoryId, synced: $synced, lastUpdated: $lastUpdated, createdAt: $createdAt, updatedAt: $updatedAt, isPinned: $isPinned, isArchived: $isArchived, isDeleted: $isDeleted, deletedAt: $deletedAt, colorValue: $colorValue, priority: $priority, tags: $tags, tasks: $tasks, links: $links, attachments: $attachments, reminderAt: $reminderAt, lockPinHash: $lockPinHash)';
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
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.synced, synced) || other.synced == synced) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isPinned, isPinned) ||
                other.isPinned == isPinned) &&
            (identical(other.isArchived, isArchived) ||
                other.isArchived == isArchived) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.colorValue, colorValue) ||
                other.colorValue == colorValue) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality().equals(other._tasks, _tasks) &&
            const DeepCollectionEquality().equals(other._links, _links) &&
            const DeepCollectionEquality().equals(
              other._attachments,
              _attachments,
            ) &&
            (identical(other.reminderAt, reminderAt) ||
                other.reminderAt == reminderAt) &&
            (identical(other.lockPinHash, lockPinHash) ||
                other.lockPinHash == lockPinHash));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    userId,
    date,
    title,
    content,
    const DeepCollectionEquality().hash(_audioMarkers),
    const DeepCollectionEquality().hash(_drawStrokes),
    audioFilePath,
    categoryId,
    synced,
    lastUpdated,
    createdAt,
    updatedAt,
    isPinned,
    isArchived,
    isDeleted,
    deletedAt,
    colorValue,
    priority,
    const DeepCollectionEquality().hash(_tags),
    const DeepCollectionEquality().hash(_tasks),
    const DeepCollectionEquality().hash(_links),
    const DeepCollectionEquality().hash(_attachments),
    reminderAt,
    lockPinHash,
  ]);

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
    @JsonKey(name: 'category_id') final String? categoryId,
    final bool synced,
    @JsonKey(name: 'last_updated') required final int lastUpdated,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
    @JsonKey(name: 'is_pinned') final bool isPinned,
    @JsonKey(name: 'is_archived') final bool isArchived,
    @JsonKey(name: 'is_deleted') final bool isDeleted,
    @JsonKey(name: 'deleted_at') final DateTime? deletedAt,
    @JsonKey(name: 'color_value') final int? colorValue,
    final int priority,
    @JsonKey(fromJson: _tagsFromJson) final List<String> tags,
    @JsonKey(name: 'tasks', fromJson: _tasksFromJson, toJson: _tasksToJson)
    final List<NoteTask> tasks,
    @JsonKey(name: 'links', fromJson: _linksFromJson, toJson: _linksToJson)
    final List<NoteLink> links,
    @JsonKey(
      name: 'attachments',
      fromJson: _attachmentsFromJson,
      toJson: _attachmentsToJson,
    )
    final List<NoteAttachment> attachments,
    @JsonKey(name: 'reminder_at') final DateTime? reminderAt,
    @JsonKey(name: 'lock_pin_hash') final String? lockPinHash,
  }) = _$DiaryEntryImpl;

  factory _DiaryEntry.fromJson(Map<String, dynamic> json) =
      _$DiaryEntryImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  String get date;
  @override
  String get title;
  @override
  String get content;
  @override
  @JsonKey(name: 'audio_markers', defaultValue: [])
  List<AudioMarker> get audioMarkers;
  @override
  @JsonKey(name: 'draw_strokes', defaultValue: [])
  List<DrawStroke> get drawStrokes;
  @override
  @JsonKey(name: 'audio_file_path')
  String? get audioFilePath;
  @override
  @JsonKey(name: 'category_id')
  String? get categoryId;
  @override
  bool get synced;
  @override
  @JsonKey(name: 'last_updated')
  int get lastUpdated;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(name: 'is_pinned')
  bool get isPinned;
  @override
  @JsonKey(name: 'is_archived')
  bool get isArchived;
  @override
  @JsonKey(name: 'is_deleted')
  bool get isDeleted;
  @override
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt;
  @override
  @JsonKey(name: 'color_value')
  int? get colorValue;
  @override
  int get priority;
  @override
  @JsonKey(fromJson: _tagsFromJson)
  List<String> get tags;
  @override
  @JsonKey(name: 'tasks', fromJson: _tasksFromJson, toJson: _tasksToJson)
  List<NoteTask> get tasks;
  @override
  @JsonKey(name: 'links', fromJson: _linksFromJson, toJson: _linksToJson)
  List<NoteLink> get links;
  @override
  @JsonKey(
    name: 'attachments',
    fromJson: _attachmentsFromJson,
    toJson: _attachmentsToJson,
  )
  List<NoteAttachment> get attachments;
  @override
  @JsonKey(name: 'reminder_at')
  DateTime? get reminderAt;
  @override
  @JsonKey(name: 'lock_pin_hash')
  String? get lockPinHash;

  /// Create a copy of DiaryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiaryEntryImplCopyWith<_$DiaryEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
