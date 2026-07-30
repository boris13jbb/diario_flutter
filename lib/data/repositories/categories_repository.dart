import 'package:injectable/injectable.dart';
import '../../domain/models/note_category.dart';
import '../remote/firestore_category_service.dart';
import '../../services/categories_service.dart';

/// Categorías con caché local y sincronización en Firestore (offline-first).
@LazySingleton()
class CategoriesRepository {
  final FirestoreCategoryService _remoteService;
  final CategoriesService _localService;

  CategoriesRepository(this._remoteService, this._localService);

  Future<List<NoteCategory>> syncCategories(String userId) async {
    List<NoteCategory> remote = [];
    try {
      remote = await _remoteService.getAllForUser(userId);
    } catch (_) {
      return _localService.loadCategories(userId);
    }

    final local = await _localService.loadCategories(userId);
    final merged = _mergeCategories(local, remote);

    final remoteIds = remote.map((c) => c.id).toSet();
    for (final category in merged) {
      if (!remoteIds.contains(category.id)) {
        try {
          await _remoteService.upsert(category, userId);
        } catch (_) {}
      }
    }

    await _localService.saveCategories(userId, merged);
    return merged;
  }

  Future<NoteCategory> createCategory({
    required String userId,
    required String name,
    required int colorValue,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('El nombre de la categoría no puede estar vacío');
    }

    final category = NoteCategory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: trimmed,
      colorValue: colorValue,
    );

    try {
      await _remoteService.create(category, userId);
    } catch (_) {}

    final current = await _localService.loadCategories(userId);
    final updated = [...current, category];
    await _localService.saveCategories(userId, updated);
    return category;
  }

  Future<NoteCategory> updateCategory({
    required String userId,
    required NoteCategory category,
  }) async {
    final trimmed = category.name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('El nombre de la categoría no puede estar vacío');
    }

    final updatedCategory = category.copyWith(name: trimmed);

    try {
      await _remoteService.upsert(updatedCategory, userId);
    } catch (_) {}

    final current = await _localService.loadCategories(userId);
    final updated = current
        .map((c) => c.id == updatedCategory.id ? updatedCategory : c)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    await _localService.saveCategories(userId, updated);
    return updatedCategory;
  }

  Future<void> deleteCategory({
    required String userId,
    required String categoryId,
  }) async {
    try {
      await _remoteService.delete(categoryId);
    } catch (_) {}

    final current = await _localService.loadCategories(userId);
    final updated = current.where((c) => c.id != categoryId).toList();
    await _localService.saveCategories(userId, updated);
  }

  Future<List<NoteCategory>> loadLocal(String userId) =>
      _localService.loadCategories(userId);

  List<NoteCategory> _mergeCategories(
    List<NoteCategory> local,
    List<NoteCategory> remote,
  ) {
    final byId = <String, NoteCategory>{
      for (final category in remote) category.id: category,
    };

    for (final category in local) {
      byId.putIfAbsent(category.id, () => category);
    }

    final merged = byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return merged;
  }
}
