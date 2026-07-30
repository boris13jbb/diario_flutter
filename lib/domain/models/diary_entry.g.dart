// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DiaryEntryImpl _$$DiaryEntryImplFromJson(Map<String, dynamic> json) =>
    _$DiaryEntryImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: json['date'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      audioMarkers:
          (json['audio_markers'] as List<dynamic>?)
              ?.map((e) => AudioMarker.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      drawStrokes:
          (json['draw_strokes'] as List<dynamic>?)
              ?.map((e) => DrawStroke.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      audioFilePath: json['audio_file_path'] as String?,
      categoryId: json['category_id'] as String?,
      synced: json['synced'] as bool? ?? false,
      lastUpdated: (json['last_updated'] as num).toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      isPinned: json['is_pinned'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      colorValue: (json['color_value'] as num?)?.toInt(),
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      tags: json['tags'] == null ? const [] : _tagsFromJson(json['tags']),
      tasks: json['tasks'] == null ? const [] : _tasksFromJson(json['tasks']),
      links: json['links'] == null ? const [] : _linksFromJson(json['links']),
      attachments: json['attachments'] == null
          ? const []
          : _attachmentsFromJson(json['attachments']),
      reminderAt: json['reminder_at'] == null
          ? null
          : DateTime.parse(json['reminder_at'] as String),
      lockPinHash: json['lock_pin_hash'] as String?,
    );

Map<String, dynamic> _$$DiaryEntryImplToJson(_$DiaryEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'date': instance.date,
      'title': instance.title,
      'content': instance.content,
      'audio_markers': instance.audioMarkers,
      'draw_strokes': instance.drawStrokes,
      'audio_file_path': instance.audioFilePath,
      'category_id': instance.categoryId,
      'synced': instance.synced,
      'last_updated': instance.lastUpdated,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'is_pinned': instance.isPinned,
      'is_archived': instance.isArchived,
      'is_deleted': instance.isDeleted,
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'color_value': instance.colorValue,
      'priority': instance.priority,
      'tags': instance.tags,
      'tasks': _tasksToJson(instance.tasks),
      'links': _linksToJson(instance.links),
      'attachments': _attachmentsToJson(instance.attachments),
      'reminder_at': instance.reminderAt?.toIso8601String(),
      'lock_pin_hash': instance.lockPinHash,
    };
