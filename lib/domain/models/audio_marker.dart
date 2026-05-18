import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_marker.freezed.dart';
part 'audio_marker.g.dart';

/// Modelo que representa un marcador temporal en una grabación de audio
@freezed
class AudioMarker with _$AudioMarker {
  const factory AudioMarker({
    required String id,
    required int timestamp, // Tiempo en milisegundos desde el inicio
    @Default('') String text, // Texto opcional asociado al marcador
  }) = _AudioMarker;

  factory AudioMarker.fromJson(Map<String, dynamic> json) =>
      _$AudioMarkerFromJson(json);
}

/// Extension para agregar métodos útiles a AudioMarker
extension AudioMarkerExtension on AudioMarker {
  /// Crea un nuevo marcador con ID automático
  static AudioMarker create({
    required int timestamp,
    String text = '',
  }) {
    return AudioMarker(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: timestamp,
      text: text,
    );
  }

  /// Formatea el timestamp en formato legible (MM:SS)
  String getFormattedTime() {
    final seconds = timestamp ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
