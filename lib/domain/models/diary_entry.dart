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
    @JsonKey(name: 'category_id') String? categoryId,
    @Default(false) bool synced, // Estado de sincronización con Firestore
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

  /// Mapa para Firestore / backend remoto.
  /// `audio_file_path` puede guardarse solo en local si no existe en el índice remoto.
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
    };
    if (categoryId != null && categoryId!.isNotEmpty) {
      map['category_id'] = categoryId;
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
