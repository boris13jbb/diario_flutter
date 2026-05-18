// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draw_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DrawPointImpl _$$DrawPointImplFromJson(Map<String, dynamic> json) =>
    _$DrawPointImpl(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      timestamp: (json['timestamp'] as num).toInt(),
    );

Map<String, dynamic> _$$DrawPointImplToJson(_$DrawPointImpl instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'timestamp': instance.timestamp,
    };
