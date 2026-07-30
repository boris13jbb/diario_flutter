import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Registro de actividades relevantes del usuario.
class ActivityLogService {
  static const _uuid = Uuid();
  static const collection = 'activity_logs';
  static const _localKeyPrefix = 'activity_log_';

  final FirebaseFirestore _firestore;

  ActivityLogService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> log({
    required String userId,
    required String action,
    String? noteId,
    String? detail,
  }) async {
    final entry = {
      'id': _uuid.v4(),
      'user_id': userId,
      'action': action,
      if (noteId != null) 'note_id': noteId,
      if (detail != null) 'detail': detail,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    final key = '$_localKeyPrefix$userId';
    final existing = prefs.getStringList(key) ?? <String>[];
    existing.insert(0, entry.toString());
    if (existing.length > 100) {
      existing.removeRange(100, existing.length);
    }
    await prefs.setStringList(key, existing);

    try {
      await _firestore.collection(collection).doc(entry['id'] as String).set({
        ...entry,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
