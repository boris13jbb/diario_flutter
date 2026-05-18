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
      synced: json['synced'] as bool? ?? false,
      lastUpdated: (json['last_updated'] as num).toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
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
      'synced': instance.synced,
      'last_updated': instance.lastUpdated,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
