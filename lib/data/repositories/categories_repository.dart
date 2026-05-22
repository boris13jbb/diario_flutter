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

  /// Descarga de Firestore, fusiona con caché local y sube las que falten en la nube.
  Future<List<NoteCategory>> syncCategories(String userId) async {
    List<NoteCategory> remote = [];
    try {
      remote = await _remoteService.getAllForUser(userId);
    } catch (e) {
      // Sin red: devolver solo caché local
      return _localService.loadCategories(userId);
    }

    final local = await _localService.loadCategories(userId);
    final merged = _mergeCategories(local, remote);

    final remoteIds = remote.map((c) => c.id).toSet();
    for (final category in merged) {
      if (!remoteIds.contains(category.id)) {
        try {
          await _remoteService.upsert(category, userId);
        } catch (_) {
          // Se reintentará en la próxima sincronización
        }
      }
    }

    await _localService.saveCategories(userId, merged);
    return merged;
  }

  /// Crea categoría en Firestore y actualiza la caché local.
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
    } catch (e) {
      // Guardar en local aunque falle la nube; syncCategories subirá después
    }

    final current = await _localService.loadCategories(userId);
    final updated = [...current, category];
    await _localService.saveCategories(userId, updated);
    return category;
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
