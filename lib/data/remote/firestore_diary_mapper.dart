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

  static DiaryEntry fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return DiaryEntry.fromJson(_normalize(doc.id, data));
  }

  static Map<String, dynamic> _normalize(String id, Map<String, dynamic> data) {
    return {
      'id': id,
      'user_id': data['user_id'],
      'date': data['date'] ?? '',
      'title': data['title'] ?? '',
      'content': data['content'] ?? '',
      'audio_markers': _asJsonList(data['audio_markers']),
      'draw_strokes': _asJsonList(data['draw_strokes']),
      'audio_file_path': data['audio_file_path'],
      'synced': data['synced'] ?? true,
      'last_updated': (data['last_updated'] as num?)?.toInt() ?? 0,
      'created_at': _toIsoString(data['created_at']),
      'updated_at': _toIsoString(data['updated_at']),
    };
  }

  static List<dynamic> _asJsonList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  static String? _toIsoString(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is String) return value;
    return null;
  }
}
