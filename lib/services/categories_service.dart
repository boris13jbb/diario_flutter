import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/note_category.dart';

/// Caché local de categorías (respaldo offline por usuario).
@lazySingleton
class CategoriesService {
  static const _keyPrefix = 'diary_categories_';

  Future<List<NoteCategory>> loadCategories(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$userId');
    return NoteCategory.listFromJsonString(raw);
  }

  Future<void> saveCategories(String userId, List<NoteCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyPrefix$userId',
      NoteCategory.listToJsonString(categories),
    );
  }
}
