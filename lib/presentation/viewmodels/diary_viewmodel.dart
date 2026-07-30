import 'dart:async';
import 'dart:ui' show Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/category_filter.dart';
import '../../../core/constants/diary_list_filter.dart';
import '../../../core/constants/diary_sort_order.dart';
import '../../../core/constants/sync_config.dart';
import '../../../domain/models/note_category.dart';
import '../../../data/repositories/categories_repository.dart';
import '../../../data/repositories/diary_repository.dart';
import '../../../domain/models/diary_entry.dart';
import '../../../domain/models/diary_entry_factory.dart';
import '../../../domain/models/note_task.dart';
import '../../../domain/models/note_version.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/favorites_service.dart';
import '../../../services/note_export_service.dart';
import 'auth_viewmodel.dart';

/// Estadísticas calculadas desde el estado local del diario.
class DiaryStats {
  final int totalNotes;
  final int favorites;
  final int categories;
  final int wordCount;
  final int unsynced;
  final int pinned;
  final int archived;
  final int trash;
  final int tasksCompleted;
  final int tasksPending;
  final int tasksOverdue;
  final DateTime? lastUpdated;

  const DiaryStats({
    required this.totalNotes,
    required this.favorites,
    required this.categories,
    required this.wordCount,
    required this.unsynced,
    this.pinned = 0,
    this.archived = 0,
    this.trash = 0,
    this.tasksCompleted = 0,
    this.tasksPending = 0,
    this.tasksOverdue = 0,
    this.lastUpdated,
  });
}

/// Estado del diario
class DiaryState {
  final bool isLoading;
  final List<DiaryEntry> entries;
  final DiaryEntry? selectedEntry;
  final String? error;
  final DiaryListFilter listFilter;
  final DiarySortOrder sortOrder;
  final String searchQuery;
  final Set<String> favoriteIds;
  final List<NoteCategory> categories;
  final String? categoryFilterKey;
  final bool isSyncing;
  final DateTime? lastSyncedAt;
  final String? syncMessage;

  const DiaryState({
    this.isLoading = false,
    this.entries = const [],
    this.selectedEntry,
    this.error,
    this.listFilter = DiaryListFilter.all,
    this.sortOrder = DiarySortOrder.updatedDesc,
    this.searchQuery = '',
    this.favoriteIds = const {},
    this.categories = const [],
    this.categoryFilterKey,
    this.isSyncing = false,
    this.lastSyncedAt,
    this.syncMessage,
  });

  DiaryState copyWith({
    bool? isLoading,
    List<DiaryEntry>? entries,
    DiaryEntry? selectedEntry,
    String? error,
    DiaryListFilter? listFilter,
    DiarySortOrder? sortOrder,
    String? searchQuery,
    Set<String>? favoriteIds,
    List<NoteCategory>? categories,
    String? categoryFilterKey,
    bool? isSyncing,
    DateTime? lastSyncedAt,
    String? syncMessage,
  }) {
    return DiaryState(
      isLoading: isLoading ?? this.isLoading,
      entries: entries ?? this.entries,
      selectedEntry: selectedEntry ?? this.selectedEntry,
      error: error,
      listFilter: listFilter ?? this.listFilter,
      sortOrder: sortOrder ?? this.sortOrder,
      searchQuery: searchQuery ?? this.searchQuery,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      categories: categories ?? this.categories,
      categoryFilterKey: categoryFilterKey,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncMessage: syncMessage,
    );
  }
}

/// ViewModel del diario
class DiaryViewModel extends StateNotifier<DiaryState> {
  final DiaryRepository _diaryRepository;
  final FavoritesService _favoritesService;
  final CategoriesRepository _categoriesRepository;
  final NoteExportService _exportService;
  final Ref _ref;

  StreamSubscription<List<DiaryEntry>>? _entriesSubscription;
  Timer? _autoSyncTimer;
  bool _syncInProgress = false;
  DateTime? _lastSyncAttempt;

  DiaryViewModel(
    this._diaryRepository,
    this._ref, [
    FavoritesService? favoritesService,
    CategoriesRepository? categoriesRepository,
    NoteExportService? exportService,
  ])  : _favoritesService = favoritesService ?? FavoritesService(),
        _categoriesRepository =
            categoriesRepository ?? getIt<CategoriesRepository>(),
        _exportService = exportService ?? NoteExportService(),
        super(const DiaryState());

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _entriesSubscription?.cancel();
    super.dispose();
  }

  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    _entriesSubscription?.cancel();
    _entriesSubscription = null;
  }

  void clearEntries() {
    stopAutoSync();
    state = const DiaryState();
  }

  Future<void> reloadEntries() => _loadEntries();

  void _startAutoSyncTimer() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(kAutoSyncInterval, (_) {
      unawaited(runAutoSync(showIndicator: false));
    });
  }

  Future<void> runAutoSync({
    bool showIndicator = true,
    bool force = false,
  }) async {
    if (_syncInProgress) return;

    if (!force &&
        _lastSyncAttempt != null &&
        DateTime.now().difference(_lastSyncAttempt!) < kMinSyncGap) {
      return;
    }
    _lastSyncAttempt = DateTime.now();

    final userId = _ref.read(authViewModelProvider).userId;
    if (userId == null || userId.isEmpty) return;

    _syncInProgress = true;
    if (showIndicator) {
      state = state.copyWith(isSyncing: true, error: null);
    }

    try {
      // 1) Subir pendientes locales  2) Descargar nube  3) Refrescar estado
      final result = await _diaryRepository.syncAll(userId);
      await _loadCategories(userId);
      await _loadFavorites(userId);
      final entries = await _diaryRepository.getAllEntries(userId);

      final categoryCount = state.categories.length;
      final parts = <String>[
        '${entries.length} notas',
        '$categoryCount categorías',
      ];
      if (result.uploadedCount > 0) {
        parts.add('${result.uploadedCount} subidas');
      }
      if (result.savedCount > 0) {
        parts.add('${result.savedCount} actualizadas');
      }

      state = state.copyWith(
        entries: entries,
        lastSyncedAt: DateTime.now(),
        isSyncing: false,
        syncMessage: result.remoteCount == 0 && entries.isEmpty
            ? 'No hay notas en la nube para esta cuenta'
            : parts.join(' · '),
        error: null,
      );

      _startAutoSyncTimer();
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(
        isSyncing: false,
        syncMessage: null,
        error: 'Error al sincronizar: $message',
      );
      // Mantener reintentos aunque falle la nube.
      _startAutoSyncTimer();
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> _syncAfterLocalChange() async {
    await runAutoSync(showIndicator: false, force: true);
  }

  List<DiaryEntry> get filteredEntries {
    var list = List<DiaryEntry>.from(state.entries);

    switch (state.listFilter) {
      case DiaryListFilter.favorites:
        list = list
            .where(
              (e) =>
                  !e.isDeleted &&
                  !e.isArchived &&
                  state.favoriteIds.contains(e.id),
            )
            .toList();
        break;
      case DiaryListFilter.recent:
        final cutoff =
            DateTime.now().subtract(const Duration(days: kRecentNotesDays));
        list = list
            .where(
              (e) =>
                  !e.isDeleted &&
                  !e.isArchived &&
                  _entryDateTime(e).isAfter(cutoff),
            )
            .toList();
        break;
      case DiaryListFilter.pinned:
        list = list
            .where((e) => !e.isDeleted && !e.isArchived && e.isPinned)
            .toList();
        break;
      case DiaryListFilter.archived:
        list = list.where((e) => !e.isDeleted && e.isArchived).toList();
        break;
      case DiaryListFilter.trash:
        list = list.where((e) => e.isDeleted).toList();
        break;
      case DiaryListFilter.reminders:
        list = list
            .where(
              (e) => !e.isDeleted && !e.isArchived && e.reminderAt != null,
            )
            .toList();
        break;
      case DiaryListFilter.all:
        list = list.where((e) => !e.isDeleted && !e.isArchived).toList();
        break;
    }

    // Fijadas primero en vistas activas.
    if (state.listFilter != DiaryListFilter.trash &&
        state.listFilter != DiaryListFilter.archived) {
      list.sort((a, b) {
        if (a.isPinned == b.isPinned) return 0;
        return a.isPinned ? -1 : 1;
      });
    }

    final categoryKey = state.categoryFilterKey;
    if (categoryKey != null) {
      if (categoryKey == CategoryFilterTokens.uncategorized) {
        list = list
            .where(
              (e) => e.categoryId == null || e.categoryId!.trim().isEmpty,
            )
            .toList();
      } else {
        list = list.where((e) => e.categoryId == categoryKey).toList();
      }
    }

    final query = state.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((e) {
        final categoryName =
            categoryForEntry(e)?.name.toLowerCase() ?? '';
        final tags = e.tags.map((t) => t.toLowerCase()).join(' ');
        return e.title.toLowerCase().contains(query) ||
            e.content.toLowerCase().contains(query) ||
            e.date.toLowerCase().contains(query) ||
            categoryName.contains(query) ||
            tags.contains(query);
      }).toList();
    }

    _sortEntries(list, state.sortOrder);
    return list;
  }

  void _sortEntries(List<DiaryEntry> list, DiarySortOrder order) {
    int pinAware(DiaryEntry a, DiaryEntry b, int cmp) {
      if (a.isPinned != b.isPinned &&
          state.listFilter != DiaryListFilter.trash &&
          state.listFilter != DiaryListFilter.archived) {
        return a.isPinned ? -1 : 1;
      }
      return cmp;
    }

    switch (order) {
      case DiarySortOrder.dateDesc:
        list.sort((a, b) => pinAware(a, b, b.date.compareTo(a.date)));
        break;
      case DiarySortOrder.dateAsc:
        list.sort((a, b) => pinAware(a, b, a.date.compareTo(b.date)));
        break;
      case DiarySortOrder.titleAsc:
        list.sort(
          (a, b) => pinAware(
            a,
            b,
            a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          ),
        );
        break;
      case DiarySortOrder.updatedDesc:
        list.sort(
          (a, b) => pinAware(
            a,
            b,
            _entryDateTime(b).compareTo(_entryDateTime(a)),
          ),
        );
        break;
      case DiarySortOrder.priorityDesc:
        list.sort(
          (a, b) => pinAware(a, b, b.priority.compareTo(a.priority)),
        );
        break;
    }
  }

  DateTime _entryDateTime(DiaryEntry entry) {
    return entry.updatedAt ??
        entry.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(entry.lastUpdated);
  }

  DiaryStats get stats {
    final entries = state.entries;
    var words = 0;
    DateTime? lastUpdated;
    var unsynced = 0;
    var pinned = 0;
    var archived = 0;
    var trash = 0;
    var tasksCompleted = 0;
    var tasksPending = 0;
    var tasksOverdue = 0;
    final now = DateTime.now();

    for (final entry in entries) {
      if (entry.isDeleted) {
        trash++;
      } else if (entry.isArchived) {
        archived++;
      }
      if (!entry.isDeleted && entry.isPinned) pinned++;

      final text = '${entry.title} ${entry.content}'.trim();
      if (text.isNotEmpty) {
        words += text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      }
      if (!entry.synced) unsynced++;
      for (final task in entry.tasks) {
        if (task.completed) {
          tasksCompleted++;
        } else {
          tasksPending++;
          if (task.dueAt != null && task.dueAt!.isBefore(now)) {
            tasksOverdue++;
          }
        }
      }
      final updated = _entryDateTime(entry);
      if (lastUpdated == null || updated.isAfter(lastUpdated)) {
        lastUpdated = updated;
      }
    }

    final active = entries.where((e) => !e.isDeleted && !e.isArchived).length;

    return DiaryStats(
      totalNotes: active,
      favorites: state.favoriteIds.length,
      categories: state.categories.length,
      wordCount: words,
      unsynced: unsynced,
      pinned: pinned,
      archived: archived,
      trash: trash,
      tasksCompleted: tasksCompleted,
      tasksPending: tasksPending,
      tasksOverdue: tasksOverdue,
      lastUpdated: lastUpdated,
    );
  }

  bool isFavorite(String entryId) => state.favoriteIds.contains(entryId);

  void setListFilter(DiaryListFilter filter) {
    state = state.copyWith(listFilter: filter);
  }

  void setSortOrder(DiarySortOrder order) {
    state = state.copyWith(sortOrder: order);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategoryFilter(String? categoryFilterKey) {
    state = state.copyWith(categoryFilterKey: categoryFilterKey);
  }

  String get categoryFilterLabel {
    final key = state.categoryFilterKey;
    if (key == null) return 'Categorías';
    if (key == CategoryFilterTokens.uncategorized) return 'Sin categoría';
    for (final category in state.categories) {
      if (category.id == key) return category.name;
    }
    return 'Categoría';
  }

  bool get hasActiveCategoryFilter => state.categoryFilterKey != null;

  NoteCategory? categoryForEntry(DiaryEntry entry) {
    final id = entry.categoryId;
    if (id == null || id.isEmpty) return null;
    for (final category in state.categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Future<NoteCategory?> createCategory(String name, int colorValue) async {
    final userId = _ref.read(authViewModelProvider).userId;
    if (userId == null || userId.isEmpty) return null;

    try {
      final category = await _categoriesRepository.createCategory(
        userId: userId,
        name: name,
        colorValue: colorValue,
      );
      final updated = [...state.categories, category]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      state = state.copyWith(categories: updated);
      return category;
    } catch (e) {
      state = state.copyWith(
        error:
            'No se pudo crear la categoría: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return null;
    }
  }

  Future<NoteCategory?> updateCategory(NoteCategory category) async {
    final userId = _ref.read(authViewModelProvider).userId;
    if (userId == null || userId.isEmpty) return null;

    try {
      final updated = await _categoriesRepository.updateCategory(
        userId: userId,
        category: category,
      );
      final list = state.categories
          .map((c) => c.id == updated.id ? updated : c)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      state = state.copyWith(categories: list);
      return updated;
    } catch (e) {
      state = state.copyWith(
        error:
            'No se pudo actualizar la categoría: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return null;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    final userId = _ref.read(authViewModelProvider).userId;
    if (userId == null || userId.isEmpty) return false;

    try {
      await _categoriesRepository.deleteCategory(
        userId: userId,
        categoryId: categoryId,
      );
      await _diaryRepository.clearCategoryFromEntries(categoryId);

      final entries = await _diaryRepository.getAllEntries(userId);
      final categories =
          state.categories.where((c) => c.id != categoryId).toList();
      final filterKey = state.categoryFilterKey == categoryId
          ? null
          : state.categoryFilterKey;

      state = state.copyWith(
        categories: categories,
        entries: entries,
        categoryFilterKey: filterKey,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error:
            'No se pudo eliminar la categoría: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return false;
    }
  }

  Future<void> _loadCategories(String userId) async {
    final list = await _categoriesRepository.syncCategories(userId);
    state = state.copyWith(categories: list);
  }

  Future<void> refreshCategories() async {
    final userId = _ref.read(authViewModelProvider).userId;
    if (userId == null || userId.isEmpty) return;
    await _loadCategories(userId);
  }

  Future<void> toggleFavorite(String entryId) async {
    final userId = _ref.read(authViewModelProvider).userId;
    if (userId == null || userId.isEmpty) return;

    final updated = Set<String>.from(state.favoriteIds);
    if (updated.contains(entryId)) {
      updated.remove(entryId);
    } else {
      updated.add(entryId);
    }

    state = state.copyWith(favoriteIds: updated);
    await _favoritesService.saveFavoriteIds(userId, updated);
  }

  Future<void> _loadFavorites(String userId) async {
    final ids = await _favoritesService.loadFavoriteIds(userId);
    state = state.copyWith(favoriteIds: ids);
  }

  Future<void> _loadEntries() async {
    final userId = _ref.read(authViewModelProvider).userId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    _entriesSubscription?.cancel();
    _entriesSubscription =
        _diaryRepository.watchEntries(userId).listen((entries) {
      state = state.copyWith(
        entries: entries,
        isLoading: false,
      );
    });

    // Arranca el timer aunque la primera sync falle (offline).
    _startAutoSyncTimer();

    try {
      await _loadFavorites(userId);
      // Categorías antes que notas: asegura push de catálogo pendiente a Firestore.
      await _loadCategories(userId);

      final result = await _diaryRepository.syncAll(userId);
      // Reintento de categorías tras sync de notas (red ya validada).
      await _loadCategories(userId);
      _lastSyncAttempt = DateTime.now();

      final entries = await _diaryRepository.getAllEntries(userId);
      state = state.copyWith(
        entries: entries,
        isLoading: false,
        lastSyncedAt: DateTime.now(),
        syncMessage: result.remoteCount == 0 && entries.isEmpty
            ? 'No hay notas en la nube para esta cuenta'
            : '${entries.length} notas sincronizadas',
        error: null,
      );
    } catch (e) {
      // Mostrar datos locales aunque no haya red.
      final local = await _diaryRepository.getAllEntries(userId);
      state = state.copyWith(
        entries: local,
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
        syncMessage: local.isEmpty
            ? 'Sin conexión. Reintentando automáticamente…'
            : '${local.length} notas locales · sync pendiente',
      );
    }
  }

  Future<String?> createEntry({
    required String date,
    String title = '',
    String content = '',
    String? categoryId,
    int priority = 0,
    int? colorValue,
    List<String> tags = const [],
    List<NoteTask> tasks = const [],
    DateTime? reminderAt,
  }) async {
    final userId = _ref.read(authViewModelProvider).userId;
    if (userId == null) {
      state = state.copyWith(error: 'Usuario no autenticado');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final entry = DiaryEntryFactory.create(
        userId: userId,
        date: date,
        title: title,
        content: content,
        categoryId:
            categoryId != null && categoryId.isEmpty ? null : categoryId,
        priority: priority,
        colorValue: colorValue,
        tags: tags,
        tasks: tasks,
        reminderAt: reminderAt,
      );

      await _diaryRepository.createEntry(entry);
      state = state.copyWith(isLoading: false);
      unawaited(_syncAfterLocalChange());
      return entry.id;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  Future<String?> duplicateEntry(String entryId) async {
    final userId = _ref.read(authViewModelProvider).userId;
    if (userId == null) {
      state = state.copyWith(error: 'Usuario no autenticado');
      return null;
    }

    DiaryEntry? source;
    for (final entry in state.entries) {
      if (entry.id == entryId) {
        source = entry;
        break;
      }
    }
    source ??= await _diaryRepository.getEntryById(entryId);
    if (source == null) {
      state = state.copyWith(error: 'Nota no encontrada');
      return null;
    }

    try {
      final copy = DiaryEntryFactory.create(
        userId: userId,
        date: DateTime.now().toIso8601String().split('T')[0],
        title: source.title.trim().isEmpty
            ? 'Copia'
            : '${source.title.trim()} (copia)',
        content: source.content,
        categoryId: source.categoryId,
      );
      await _diaryRepository.createEntry(copy);
      unawaited(_syncAfterLocalChange());
      return copy.id;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  Future<String?> exportEntry(
    String entryId, {
    NoteExportFormat format = NoteExportFormat.markdown,
  }) async {
    DiaryEntry? entry;
    for (final e in state.entries) {
      if (e.id == entryId) {
        entry = e;
        break;
      }
    }
    entry ??= await _diaryRepository.getEntryById(entryId);
    if (entry == null) {
      state = state.copyWith(error: 'Nota no encontrada');
      return null;
    }

    try {
      return await _exportService.exportEntry(
        entry,
        format: format,
        categories: state.categories,
      );
    } catch (e) {
      state = state.copyWith(
        error:
            'No se pudo exportar: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return null;
    }
  }

  /// Comparte la nota con el diálogo nativo del sistema (junto a exportar).
  Future<bool> shareEntry(
    String entryId, {
    NoteExportFormat format = NoteExportFormat.markdown,
    Rect? sharePositionOrigin,
  }) async {
    DiaryEntry? entry;
    for (final e in state.entries) {
      if (e.id == entryId) {
        entry = e;
        break;
      }
    }
    entry ??= await _diaryRepository.getEntryById(entryId);
    if (entry == null) {
      state = state.copyWith(error: 'Nota no encontrada');
      return false;
    }

    try {
      await _exportService.shareEntry(
        entry,
        format: format,
        categories: state.categories,
        sharePositionOrigin: sharePositionOrigin,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error:
            'No se pudo compartir: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return false;
    }
  }

  Future<String?> exportAllEntries({
    NoteExportFormat format = NoteExportFormat.markdown,
  }) async {
    try {
      return await _exportService.exportAll(
        state.entries.where((e) => !e.isDeleted).toList(),
        format: format,
        categories: state.categories,
      );
    } catch (e) {
      state = state.copyWith(
        error:
            'No se pudo exportar: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return null;
    }
  }

  Future<String?> exportBackup() async {
    try {
      return await _exportService.exportBackupJson(state.entries);
    } catch (e) {
      state = state.copyWith(
        error:
            'No se pudo crear el respaldo: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return null;
    }
  }

  Future<void> printEntry(String entryId) async {
    DiaryEntry? entry;
    for (final e in state.entries) {
      if (e.id == entryId) {
        entry = e;
        break;
      }
    }
    entry ??= await _diaryRepository.getEntryById(entryId);
    if (entry == null) {
      state = state.copyWith(error: 'Nota no encontrada');
      return;
    }
    try {
      await _exportService.printEntry(entry, categories: state.categories);
    } catch (e) {
      state = state.copyWith(
        error:
            'No se pudo imprimir: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  Future<bool> updateEntry(DiaryEntry entry, {bool quiet = false}) async {
    if (!quiet) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      await _diaryRepository.updateEntry(entry);
      if (!quiet) {
        state = state.copyWith(isLoading: false);
      }
      unawaited(_syncAfterLocalChange());
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> togglePin(String entryId) async {
    final entry = await _findEntry(entryId);
    if (entry == null) return false;
    return updateEntry(entry.copyWith(isPinned: !entry.isPinned));
  }

  Future<bool> archiveEntry(String entryId, {bool archive = true}) async {
    final entry = await _findEntry(entryId);
    if (entry == null) return false;
    return updateEntry(
      entry.copyWith(isArchived: archive, isPinned: archive ? false : entry.isPinned),
    );
  }

  Future<bool> moveToTrash(String entryId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _diaryRepository.softDeleteEntry(entryId);
      final favorites = Set<String>.from(state.favoriteIds)..remove(entryId);
      final userId = _ref.read(authViewModelProvider).userId;
      if (userId != null) {
        await _favoritesService.saveFavoriteIds(userId, favorites);
      }
      state = state.copyWith(isLoading: false, favoriteIds: favorites);
      unawaited(_syncAfterLocalChange());
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> restoreFromTrash(String entryId) async {
    try {
      await _diaryRepository.restoreEntry(entryId);
      unawaited(_syncAfterLocalChange());
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> permanentlyDelete(String entryId) async {
    try {
      await _diaryRepository.hardDeleteEntry(entryId);
      final favorites = Set<String>.from(state.favoriteIds)..remove(entryId);
      final userId = _ref.read(authViewModelProvider).userId;
      if (userId != null) {
        await _favoritesService.saveFavoriteIds(userId, favorites);
      }
      state = state.copyWith(favoriteIds: favorites);
      unawaited(_syncAfterLocalChange());
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> emptyTrash() async {
    final userId = _ref.read(authViewModelProvider).userId;
    if (userId == null) return false;
    try {
      await _diaryRepository.emptyTrash(userId);
      unawaited(_syncAfterLocalChange());
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<List<NoteVersion>> getVersions(String noteId) {
    return _diaryRepository.getVersions(noteId);
  }

  Future<bool> restoreVersion(NoteVersion version) async {
    try {
      await _diaryRepository.restoreFromVersion(version);
      unawaited(_syncAfterLocalChange());
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<DiaryEntry?> _findEntry(String entryId) async {
    for (final e in state.entries) {
      if (e.id == entryId) return e;
    }
    return _diaryRepository.getEntryById(entryId);
  }

  /// Elimina (soft) — mantiene compatibilidad con UI existente.
  Future<bool> deleteEntry(String entryId) => moveToTrash(entryId);

  void selectEntry(DiaryEntry entry) {
    state = state.copyWith(selectedEntry: entry);
  }

  void clearSelection() {
    state = state.copyWith(selectedEntry: null);
  }

  Future<void> syncPendingEntries() async {
    try {
      await runAutoSync(showIndicator: true, force: true);
    } catch (e) {
      state = state.copyWith(
        error:
            'Error al sincronizar: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  void onAppResumed() {
    final userId = _ref.read(authViewModelProvider).userId;
    if (userId == null || userId.isEmpty) return;

    // Si nunca cargó (sesión fría), arranca el ciclo completo.
    if (_autoSyncTimer == null) {
      unawaited(reloadEntries());
      return;
    }
    unawaited(runAutoSync(showIndicator: true, force: true));
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final diaryViewModelProvider =
    StateNotifierProvider<DiaryViewModel, DiaryState>((ref) {
  final diaryRepository = getIt<DiaryRepository>();
  final viewModel = DiaryViewModel(diaryRepository, ref);

  ref.onDispose(viewModel.dispose);

  // Dispara también el estado inicial (sesión ya autenticada al abrir la app).
  ref.listen<AuthState>(
    authViewModelProvider,
    (previous, next) {
      if (!next.isAuthenticated ||
          next.userId == null ||
          next.userId!.isEmpty) {
        viewModel.clearEntries();
        return;
      }

      final shouldReload = previous == null ||
          !previous.isAuthenticated ||
          previous.userId != next.userId;

      if (shouldReload) {
        unawaited(viewModel.reloadEntries());
      }
    },
    fireImmediately: true,
  );

  return viewModel;
});
