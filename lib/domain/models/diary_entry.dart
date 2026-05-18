import 'package:freezed_annotation/freezed_annotation.dart';
import 'audio_marker.dart';
import 'draw_stroke.dart';

part 'diary_entry.freezed.dart';
part 'diary_entry.g.dart';

/// Modelo que representa una entrada del diario
@freezed
class DiaryEntry with _$DiaryEntry {
  const factory DiaryEntry({
    required String id,
    @JsonKey(name: 'user_id') required String userId, // ID del usuario propietario
    required String date,
    required String title,
    required String content,
    @JsonKey(name: 'audio_markers', defaultValue: []) @Default([]) List<AudioMarker> audioMarkers, // Marcadores de audio
    @JsonKey(name: 'draw_strokes', defaultValue: []) @Default([]) List<DrawStroke> drawStrokes, // Trazos de dibujo
    @JsonKey(name: 'audio_file_path') String? audioFilePath, // Ruta al archivo de audio grabado
    @Default(false) bool synced, // Estado de sincronización con Supabase
    @JsonKey(name: 'last_updated') required int lastUpdated, // Timestamp de última actualización
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _DiaryEntry;

  factory DiaryEntry.fromJson(Map<String, dynamic> json) =>
      _$DiaryEntryFromJson(json);
}

/// Extension para agregar métodos útiles a DiaryEntry
extension DiaryEntryExtension on DiaryEntry {
  /// Verifica si la entrada tiene contenido multimedia
  bool get hasMultimedia =>
      audioMarkers.isNotEmpty || drawStrokes.isNotEmpty || audioFilePath != null;

  /// Obtiene una copia actualizada con nuevo timestamp
  DiaryEntry copyWithUpdatedTimestamp() {
    return copyWith(
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now(),
      synced: false,
    );
  }
}
