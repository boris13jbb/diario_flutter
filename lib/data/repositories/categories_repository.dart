import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../domain/models/note_category.dart';
import '../remote/firestore_category_service.dart';
import '../../services/categories_service.dart';

/// Fusiona catálogo local y remoto.
///
/// Remoto es la base; lo local solo se añade si no existe en remoto
/// y no está marcado como borrado pendiente (evita resucitar eliminadas).
List<NoteCategory> mergeNoteCategories({
  required List<NoteCategory> local,
  required List<NoteCategory> remote,
  Set<String> pendingDeleteIds = const {},
}) {
  final byId = <String, NoteCategory>{
    for (final category in remote)
      if (!pendingDeleteIds.contains(category.id)) category.id: category,
  };

  for (final category in local) {
    if (pendingDeleteIds.contains(category.id)) continue;
    byId.putIfAbsent(category.id, () => category);
  }

  final merged = byId.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return merged;
}

/// Categorías con caché local y sincronización en Firestore (offline-first).
///
/// Las escrituras remotas fallidas quedan en cola pendiente y se reintentan
/// en cada [syncCategories], para que otro dispositivo pueda recuperarlas.
@LazySingleton()
class CategoriesRepository {
  final FirestoreCategoryService _remoteService;
  final CategoriesService _localService;

  CategoriesRepository(this._remoteService, this._localService);

  /// Descarga remotas, fusiona con locales, reintenta pendientes y persiste.
  Future<List<NoteCategory>> syncCategories(String userId) async {
    final local = await _localService.loadCategories(userId);
    final pendingUpserts = await _localService.loadPendingUpsertIds(userId);
    final pendingDeletes = await _localService.loadPendingDeleteIds(userId);

    List<NoteCategory>? remote;
    try {
      remote = await _remoteService.getAllForUser(userId);
    } catch (e, st) {
      debugPrint('CategoriesRepository.syncCategories: lectura remota falló: $e');
      debugPrint('$st');
      await _flushPendingUpserts(
        userId: userId,
        categories: local,
        pendingUpsertIds: pendingUpserts,
      );
      await _flushPendingDeletes(userId, pendingDeletes);
      return local;
    }

    await _flushPendingDeletes(userId, pendingDeletes);
    final remainingDeletes =
        await _localService.loadPendingDeleteIds(userId);

    final remoteAfterDeletes = remote
        .where((c) => !remainingDeletes.contains(c.id))
        .toList(growable: false);

    final merged = mergeNoteCategories(
      local: local,
      remote: remoteAfterDeletes,
      pendingDeleteIds: remainingDeletes,
    );

    final remoteIds = remoteAfterDeletes.map((c) => c.id).toSet();
    final toPush = merged.where(
      (c) => !remoteIds.contains(c.id) || pendingUpserts.contains(c.id),
    );

    for (final category in toPush) {
      try {
        await _remoteService.upsert(category, userId);
        await _localService.clearPendingUpsert(userId, category.id);
      } catch (e, st) {
        debugPrint(
          'CategoriesRepository.syncCategories: no se pudo subir ${category.id}: $e',
        );
        debugPrint('$st');
        await _localService.markPendingUpsert(userId, category.id);
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

    final current = await _localService.loadCategories(userId);
    final updated = [...current, category]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    await _localService.saveCategories(userId, updated);
    await _localService.markPendingUpsert(userId, category.id);

    try {
      await _remoteService.create(category, userId);
      await _localService.clearPendingUpsert(userId, category.id);
    } catch (e, st) {
      debugPrint('CategoriesRepository.createCategory: remoto pendiente: $e');
      debugPrint('$st');
    }

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

    final current = await _localService.loadCategories(userId);
    final updated = current
        .map((c) => c.id == updatedCategory.id ? updatedCategory : c)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    await _localService.saveCategories(userId, updated);
    await _localService.markPendingUpsert(userId, updatedCategory.id);

    try {
      await _remoteService.upsert(updatedCategory, userId);
      await _localService.clearPendingUpsert(userId, updatedCategory.id);
    } catch (e, st) {
      debugPrint('CategoriesRepository.updateCategory: remoto pendiente: $e');
      debugPrint('$st');
    }

    return updatedCategory;
  }

  Future<void> deleteCategory({
    required String userId,
    required String categoryId,
  }) async {
    final current = await _localService.loadCategories(userId);
    final updated = current.where((c) => c.id != categoryId).toList();
    await _localService.saveCategories(userId, updated);
    await _localService.markPendingDelete(userId, categoryId);

    try {
      await _remoteService.delete(categoryId);
      await _localService.clearPendingDelete(userId, categoryId);
    } catch (e, st) {
      debugPrint('CategoriesRepository.deleteCategory: remoto pendiente: $e');
      debugPrint('$st');
    }
  }

  Future<List<NoteCategory>> loadLocal(String userId) =>
      _localService.loadCategories(userId);

  Future<void> _flushPendingUpserts({
    required String userId,
    required List<NoteCategory> categories,
    required Set<String> pendingUpsertIds,
  }) async {
    if (pendingUpsertIds.isEmpty) return;

    final byId = {for (final c in categories) c.id: c};
    for (final id in pendingUpsertIds) {
      final category = byId[id];
      if (category == null) {
        await _localService.clearPendingUpsert(userId, id);
        continue;
      }
      try {
        await _remoteService.upsert(category, userId);
        await _localService.clearPendingUpsert(userId, id);
      } catch (e, st) {
        debugPrint(
          'CategoriesRepository._flushPendingUpserts: $id pendiente: $e',
        );
        debugPrint('$st');
      }
    }
  }

  Future<void> _flushPendingDeletes(
    String userId,
    Set<String> pendingDeleteIds,
  ) async {
    for (final id in pendingDeleteIds) {
      try {
        await _remoteService.delete(id);
        await _localService.clearPendingDelete(userId, id);
      } catch (e, st) {
        debugPrint(
          'CategoriesRepository._flushPendingDeletes: $id pendiente: $e',
        );
        debugPrint('$st');
      }
    }
  }
}
