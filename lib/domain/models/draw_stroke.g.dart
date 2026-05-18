// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draw_stroke.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DrawStrokeImpl _$$DrawStrokeImplFromJson(Map<String, dynamic> json) =>
    _$DrawStrokeImpl(
      id: json['id'] as String,
      points: (json['points'] as List<dynamic>)
          .map((e) => DrawPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      color: (json['color'] as num).toInt(),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      startTimestamp: (json['startTimestamp'] as num).toInt(),
    );

Map<String, dynamic> _$$DrawStrokeImplToJson(_$DrawStrokeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'points': instance.points,
      'color': instance.color,
      'strokeWidth': instance.strokeWidth,
      'startTimestamp': instance.startTimestamp,
    };
