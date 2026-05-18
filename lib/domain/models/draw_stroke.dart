import 'package:freezed_annotation/freezed_annotation.dart';
import 'draw_point.dart';

part 'draw_stroke.freezed.dart';
part 'draw_stroke.g.dart';

/// Modelo que representa un trazo completo de dibujo
@freezed
class DrawStroke with _$DrawStroke {
  const factory DrawStroke({
    required String id,
    required List<DrawPoint> points, // Lista de puntos que forman el trazo
    required int color, // Color del trazo (ARGB como entero)
    @Default(2.0) double strokeWidth, // Grosor del trazo
    required int startTimestamp, // Timestamp del inicio del trazo
  }) = _DrawStroke;

  factory DrawStroke.fromJson(Map<String, dynamic> json) =>
      _$DrawStrokeFromJson(json);
}

/// Extension para agregar métodos útiles a DrawStroke
extension DrawStrokeExtension on DrawStroke {
  /// Obtiene la duración del trazo en milisegundos
  int getDuration() {
    if (points.isEmpty) return 0;
    return points.last.timestamp - points.first.timestamp;
  }

  /// Obtiene el timestamp del último punto
  int getEndTimestamp() {
    return points.isNotEmpty ? points.last.timestamp : startTimestamp;
  }

  /// Crea un nuevo trazo con ID automático
  static DrawStroke create({
    required List<DrawPoint> points,
    required int color,
    double strokeWidth = 2.0,
    required int startTimestamp,
  }) {
    return DrawStroke(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      points: points,
      color: color,
      strokeWidth: strokeWidth,
      startTimestamp: startTimestamp,
    );
  }
}
