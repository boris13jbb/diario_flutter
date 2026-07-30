import 'package:freezed_annotation/freezed_annotation.dart';
import 'audio_marker.dart';
import 'draw_stroke.dart';
import 'note_attachment.dart';
import 'note_link.dart';
import 'note_task.dart';

part 'diary_entry.freezed.dart';
part 'diary_entry.g.dart';

List<NoteTask> _tasksFromJson(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => NoteTask.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

List<Map<String, dynamic>> _tasksToJson(List<NoteTask> tasks) =>
    tasks.map((t) => t.toJson()).toList();

List<NoteLink> _linksFromJson(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => NoteLink.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

List<Map<String, dynamic>> _linksToJson(List<NoteLink> links) =>
    links.map((l) => l.toJson()).toList();

List<NoteAttachment> _attachmentsFromJson(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => NoteAttachment.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

List<Map<String, dynamic>> _attachmentsToJson(List<NoteAttachment> items) =>
    items.map((a) => a.toJson()).toList();

List<String> _tagsFromJson(dynamic value) {
  if (value is! List) return const [];
  return value.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
}

/// Modelo que representa una entrada del diario / nota.
@freezed
class DiaryEntry with _$DiaryEntry {
  const factory DiaryEntry({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String date,
    required String title,
    required String content,
    @JsonKey(name: 'audio_markers', defaultValue: [])
    @Default([])
    List<AudioMarker> audioMarkers,
    @JsonKey(name: 'draw_strokes', defaultValue: [])
    @Default([])
    List<DrawStroke> drawStrokes,
    @JsonKey(name: 'audio_file_path') String? audioFilePath,
    @JsonKey(name: 'category_id') String? categoryId,
    @Default(false) bool synced,
    @JsonKey(name: 'last_updated') required int lastUpdated,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'is_pinned') @Default(false) bool isPinned,
    @JsonKey(name: 'is_archived') @Default(false) bool isArchived,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'color_value') int? colorValue,
    @Default(0) int priority,
    @JsonKey(fromJson: _tagsFromJson) @Default([]) List<String> tags,
    @JsonKey(name: 'tasks', fromJson: _tasksFromJson, toJson: _tasksToJson)
    @Default([])
    List<NoteTask> tasks,
    @JsonKey(name: 'links', fromJson: _linksFromJson, toJson: _linksToJson)
    @Default([])
    List<NoteLink> links,
    @JsonKey(
      name: 'attachments',
      fromJson: _attachmentsFromJson,
      toJson: _attachmentsToJson,
    )
    @Default([])
    List<NoteAttachment> attachments,
    @JsonKey(name: 'reminder_at') DateTime? reminderAt,
    @JsonKey(name: 'lock_pin_hash') String? lockPinHash,
  }) = _DiaryEntry;

  factory DiaryEntry.fromJson(Map<String, dynamic> json) =>
      _$DiaryEntryFromJson(json);
}

/// Extension para agregar métodos útiles a DiaryEntry
extension DiaryEntryExtension on DiaryEntry {
  bool get hasMultimedia =>
      audioMarkers.isNotEmpty ||
      drawStrokes.isNotEmpty ||
      audioFilePath != null ||
      attachments.isNotEmpty;

  bool get isLocked => lockPinHash != null && lockPinHash!.isNotEmpty;

  bool get isActive => !isDeleted && !isArchived;

  DiaryEntry copyWithUpdatedTimestamp() {
    return copyWith(
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now(),
      synced: false,
    );
  }

  /// Mapa para Firestore / backend remoto.
  Map<String, dynamic> toRemoteMap() {
    final map = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'date': date,
      'title': title,
      'content': content,
      'last_updated': lastUpdated,
      'synced': synced,
      'audio_markers': audioMarkers.map((m) => m.toJson()).toList(),
      'draw_strokes': drawStrokes.map((s) => s.toJson()).toList(),
      'is_pinned': isPinned,
      'is_archived': isArchived,
      'is_deleted': isDeleted,
      'priority': priority,
      'tags': tags,
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'links': links.map((l) => l.toJson()).toList(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
    if (categoryId != null && categoryId!.isNotEmpty) {
      map['category_id'] = categoryId;
    }
    if (colorValue != null) {
      map['color_value'] = colorValue;
    }
    if (deletedAt != null) {
      map['deleted_at'] = deletedAt!.toUtc().toIso8601String();
    }
    if (reminderAt != null) {
      map['reminder_at'] = reminderAt!.toUtc().toIso8601String();
    }
    if (lockPinHash != null && lockPinHash!.isNotEmpty) {
      map['lock_pin_hash'] = lockPinHash;
    }
    if (createdAt != null) {
      map['created_at'] = createdAt!.toUtc().toIso8601String();
    }
    if (updatedAt != null) {
      map['updated_at'] = updatedAt!.toUtc().toIso8601String();
    }
    return map;
  }
}
