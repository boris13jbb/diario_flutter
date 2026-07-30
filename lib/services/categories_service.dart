import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/note_category.dart';

/// Caché local de categorías y cola de sincronización pendiente por usuario.
@lazySingleton
class CategoriesService {
  static const _keyPrefix = 'diary_categories_';
  static const _pendingUpsertPrefix = 'diary_categories_pending_upsert_';
  static const _pendingDeletePrefix = 'diary_categories_pending_delete_';

  Future<List<NoteCategory>> loadCategories(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$userId');
    return NoteCategory.listFromJsonString(raw);
  }

  Future<void> saveCategories(
    String userId,
    List<NoteCategory> categories,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyPrefix$userId',
      NoteCategory.listToJsonString(categories),
    );
  }

  Future<Set<String>> loadPendingUpsertIds(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('$_pendingUpsertPrefix$userId') ?? const [];
    return raw.toSet();
  }

  Future<Set<String>> loadPendingDeleteIds(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('$_pendingDeletePrefix$userId') ?? const [];
    return raw.toSet();
  }

  Future<void> markPendingUpsert(String userId, String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await loadPendingUpsertIds(userId)..add(categoryId);
    // Si volvió a crearse, ya no debe quedar como borrado pendiente.
    final deletes = await loadPendingDeleteIds(userId)..remove(categoryId);
    await prefs.setStringList(
      '$_pendingUpsertPrefix$userId',
      ids.toList(growable: false),
    );
    await prefs.setStringList(
      '$_pendingDeletePrefix$userId',
      deletes.toList(growable: false),
    );
  }

  Future<void> clearPendingUpsert(String userId, String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await loadPendingUpsertIds(userId)..remove(categoryId);
    await prefs.setStringList(
      '$_pendingUpsertPrefix$userId',
      ids.toList(growable: false),
    );
  }

  Future<void> markPendingDelete(String userId, String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final deletes = await loadPendingDeleteIds(userId)..add(categoryId);
    final upserts = await loadPendingUpsertIds(userId)..remove(categoryId);
    await prefs.setStringList(
      '$_pendingDeletePrefix$userId',
      deletes.toList(growable: false),
    );
    await prefs.setStringList(
      '$_pendingUpsertPrefix$userId',
      upserts.toList(growable: false),
    );
  }

  Future<void> clearPendingDelete(String userId, String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await loadPendingDeleteIds(userId)..remove(categoryId);
    await prefs.setStringList(
      '$_pendingDeletePrefix$userId',
      ids.toList(growable: false),
    );
  }
}
