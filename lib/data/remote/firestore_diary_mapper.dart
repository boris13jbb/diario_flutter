import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/diary_entry.dart';

/// Conversión entre [DiaryEntry] y documentos de Firestore.
class FirestoreDiaryMapper {
  static const String collection = 'diary_entries';

  static Map<String, dynamic> toFirestore(DiaryEntry entry) {
    final map = entry.toRemoteMap();
    if (entry.createdAt != null) {
      map['created_at'] = Timestamp.fromDate(entry.createdAt!.toUtc());
    }
    if (entry.updatedAt != null) {
      map['updated_at'] = Timestamp.fromDate(entry.updatedAt!.toUtc());
    }
    return map;
  }

  /// Convierte un documento de Firestore; devuelve null si el JSON no es válido.
  static DiaryEntry? tryFromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    try {
      final data = doc.data();
      if (data == null) return null;
      return DiaryEntry.fromJson(_normalize(doc.id, data));
    } catch (e) {
      // Evita que un documento corrupto bloquee toda la sincronización.
      return null;
    }
  }

  static DiaryEntry fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return tryFromDocument(doc) ??
        (throw FormatException('Documento inválido: ${doc.id}'));
  }

  static Map<String, dynamic> _normalize(String id, Map<String, dynamic> data) {
    return {
      'id': id,
      'user_id': data['user_id']?.toString() ?? '',
      'date': data['date']?.toString() ?? '',
      'title': data['title']?.toString() ?? '',
      'content': data['content']?.toString() ?? '',
      'audio_markers': _safeMarkerMaps(data['audio_markers']),
      'draw_strokes': _safeStrokeMaps(data['draw_strokes']),
      'audio_file_path': data['audio_file_path']?.toString(),
      'category_id': data['category_id']?.toString(),
      'synced': data['synced'] == true,
      'last_updated': (data['last_updated'] as num?)?.toInt() ?? 0,
      'created_at': _toIsoString(data['created_at']),
      'updated_at': _toIsoString(data['updated_at']),
    };
  }

  /// Solo incluye mapas válidos para [AudioMarker.fromJson].
  static List<Map<String, dynamic>> _safeMarkerMaps(dynamic value) {
    if (value is! List) return const [];
    final result = <Map<String, dynamic>>[];
    for (final item in value) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      if (map['id'] == null || map['timestamp'] == null) continue;
      result.add(map);
    }
    return result;
  }

  /// Solo incluye mapas válidos para [DrawStroke.fromJson].
  static List<Map<String, dynamic>> _safeStrokeMaps(dynamic value) {
    if (value is! List) return const [];
    final result = <Map<String, dynamic>>[];
    for (final item in value) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      if (map['id'] == null || map['points'] == null) continue;
      result.add(map);
    }
    return result;
  }

  static String? _toIsoString(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is String) return value;
    return null;
  }
}
