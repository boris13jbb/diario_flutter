import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Favoritos offline-first: SharedPreferences + documento Firestore por usuario.
class FavoritesService {
  static const _keyPrefix = 'diary_favorites_';
  static const _collection = 'user_settings';

  final FirebaseFirestore _firestore;

  FavoritesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Set<String>> loadFavoriteIds(String userId) async {
    final local = await _loadLocal(userId);

    try {
      final doc =
          await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) {
        if (local.isNotEmpty) {
          await _saveRemote(userId, local);
        }
        return local;
      }

      final remoteList = (doc.data()?['favorite_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          <String>{};

      final merged = {...local, ...remoteList};
      await _saveLocal(userId, merged);
      if (merged.length != remoteList.length ||
          !merged.containsAll(remoteList)) {
        await _saveRemote(userId, merged);
      }
      return merged;
    } catch (_) {
      return local;
    }
  }

  Future<void> saveFavoriteIds(String userId, Set<String> ids) async {
    await _saveLocal(userId, ids);
    try {
      await _saveRemote(userId, ids);
    } catch (_) {
      // Se reintentará en la próxima carga/sincronización.
    }
  }

  Future<Set<String>> _loadLocal(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('$_keyPrefix$userId');
    return list != null ? list.toSet() : {};
  }

  Future<void> _saveLocal(String userId, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_keyPrefix$userId', ids.toList());
  }

  Future<void> _saveRemote(String userId, Set<String> ids) async {
    await _firestore.collection(_collection).doc(userId).set(
      {
        'user_id': userId,
        'favorite_ids': ids.toList(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
