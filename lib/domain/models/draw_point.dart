import 'package:freezed_annotation/freezed_annotation.dart';

part 'draw_point.freezed.dart';
part 'draw_point.g.dart';

/// Modelo que representa un punto en un trazo de dibujo
@freezed
class DrawPoint with _$DrawPoint {
  const factory DrawPoint({
    required double x, // Posición X en el canvas
    required double y, // Posición Y en el canvas
    required int timestamp, // Tiempo en milisegundos desde el inicio del dibujo
  }) = _DrawPoint;

  factory DrawPoint.fromJson(Map<String, dynamic> json) =>
      _$DrawPointFromJson(json);
}
