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
    if (entry.deletedAt != null) {
      map['deleted_at'] = Timestamp.fromDate(entry.deletedAt!.toUtc());
    }
    if (entry.reminderAt != null) {
      map['reminder_at'] = Timestamp.fromDate(entry.reminderAt!.toUtc());
    }
    return map;
  }

  static DiaryEntry? tryFromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    try {
      final data = doc.data();
      if (data == null) return null;
      return DiaryEntry.fromJson(_normalize(doc.id, data));
    } catch (_) {
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
      'is_pinned': data['is_pinned'] == true,
      'is_archived': data['is_archived'] == true,
      'is_deleted': data['is_deleted'] == true,
      'deleted_at': _toIsoString(data['deleted_at']),
      'color_value': (data['color_value'] as num?)?.toInt(),
      'priority': (data['priority'] as num?)?.toInt() ?? 0,
      'tags': data['tags'] is List
          ? (data['tags'] as List).map((e) => e.toString()).toList()
          : const <String>[],
      'tasks': data['tasks'] is List ? data['tasks'] : const [],
      'links': data['links'] is List ? data['links'] : const [],
      'attachments':
          data['attachments'] is List ? data['attachments'] : const [],
      'reminder_at': _toIsoString(data['reminder_at']),
      'lock_pin_hash': data['lock_pin_hash']?.toString(),
    };
  }

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
