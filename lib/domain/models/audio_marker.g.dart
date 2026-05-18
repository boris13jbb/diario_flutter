// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_marker.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AudioMarkerImpl _$$AudioMarkerImplFromJson(Map<String, dynamic> json) =>
    _$AudioMarkerImpl(
      id: json['id'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      text: json['text'] as String? ?? '',
    );

Map<String, dynamic> _$$AudioMarkerImplToJson(_$AudioMarkerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp,
      'text': instance.text,
    };
