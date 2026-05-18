import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local de IDs de notas marcadas como favoritas (por usuario).
class FavoritesService {
  static const _keyPrefix = 'diary_favorites_';

  Future<Set<String>> loadFavoriteIds(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('$_keyPrefix$userId');
    return list != null ? list.toSet() : {};
  }

  Future<void> saveFavoriteIds(String userId, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_keyPrefix$userId', ids.toList());
  }
}
