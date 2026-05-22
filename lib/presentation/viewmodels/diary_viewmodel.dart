import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/category_filter.dart';
import '../../../core/constants/diary_list_filter.dart';
import '../../../core/constants/sync_config.dart';
import '../../../domain/models/note_category.dart';
import '../../../data/repositories/categories_repository.dart';
import '../../../data/repositories/diary_repository.dart';
import '../../../domain/models/diary_entry.dart';
import '../../../domain/models/diary_entry_factory.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/favorites_service.dart';
import 'auth_viewmodel.dart';

/// Estado del diario
class DiaryState {
  final bool isLoading;
  final List<DiaryEntry> entries;
  final DiaryEntry? selectedEntry;
  final String? error;
  final DiaryListFilter listFilter;
  final String searchQuery;
  final Set<String> favoriteIds;
  final List<NoteCategory> categories;
  /// null = todas; [CategoryFilterTokens.uncategorized] o id de categoría.
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
  ])  : _favoritesService = favoritesService ?? FavoritesService(),
        _categoriesRepository =
            categoriesRepository ?? getIt<CategoriesRepository>(),
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

  /// Recarga notas y reinicia sincronización (tras login o cambio de usuario).
  Future<void> reloadEntries() => _loadEntries();

  void _startAutoSyncTimer() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(kAutoSyncInterval, (_) {
      unawaited(runAutoSync(showIndicator: false));
    });
  }

  /// Sincronización bidireccional automática o manual.
  Future<void> runAutoSync({bool showIndicator = true, bool force = false}) async {
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
      state = state.copyWith(isSyncing: true);
    }

    try {
      final download = await _diaryRepository.downloadEntriesFromFirestore(userId);
      await _diaryRepository.syncPendingEntries();
      await _loadCategories(userId);
      final entries = await _diaryRepository.getAllEntries(userId);

      final categoryCount = state.categories.length;
      state = state.copyWith(
        entries: entries,
        lastSyncedAt: DateTime.now(),
        isSyncing: false,
        syncMessage: download.remoteCount == 0
            ? 'No hay notas en la nube para esta cuenta'
            : '${entries.length} notas · $categoryCount categorías sincronizadas',
        error: null,
      );
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(
        isSyncing: false,
        syncMessage: null,
        error: 'Error al sincronizar: $message',
      );
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> _syncAfterLocalChange() async {
    await runAutoSync(showIndicator: false, force: true);
  }

  /// Entradas visibles según filtro activo, búsqueda y orden por fecha.
  List<DiaryEntry> get filteredEntries {
    var list = List<DiaryEntry>.from(state.entries);

    switch (state.listFilter) {
      case DiaryListFilter.favorites:
        list = list.where((e) => state.favoriteIds.contains(e.id)).toList();
        break;
      case DiaryListFilter.recent:
        final cutoff = DateTime.now().subtract(const Duration(days: kRecentNotesDays));
        list = list.where((e) => _entryDateTime(e).isAfter(cutoff)).toList();
        break;
      case DiaryListFilter.all:
        break;
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
      list = list
          .where(
            (e) =>
                e.title.toLowerCase().contains(query) ||
                e.content.toLowerCase().contains(query) ||
                e.date.toLowerCase().contains(query),
          )
          .toList();
    }

    list.sort((a, b) => _entryDateTime(b).compareTo(_entryDateTime(a)));
    return list;
  }

  DateTime _entryDateTime(DiaryEntry entry) {
    return entry.updatedAt ??
        entry.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(entry.lastUpdated);
  }

  bool isFavorite(String entryId) => state.favoriteIds.contains(entryId);

  void setListFilter(DiaryListFilter filter) {
    state = state.copyWith(listFilter: filter);
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
        error: 'No se pudo crear la categoría: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return null;
    }
  }

  Future<void> _loadCategories(String userId) async {
    final list = await _categoriesRepository.syncCategories(userId);
    state = state.copyWith(categories: list);
  }

  /// Sincroniza categorías con Firestore (antes de abrir el selector).
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

  /// Cargar entradas del usuario actual
  Future<void> _loadEntries() async {
    final userId = _ref.read(authViewModelProvider).userId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    _entriesSubscription?.cancel();
    _entriesSubscription = _diaryRepository.watchEntries(userId).listen((entries) {
      state = state.copyWith(
        entries: entries,
        isLoading: false,
      );
    });

    try {
      await _loadFavorites(userId);

      final download = await _diaryRepository.downloadEntriesFromFirestore(userId);
      await _loadCategories(userId);
      await _diaryRepository.syncPendingEntries();
      _lastSyncAttempt = DateTime.now();

      final entries = await _diaryRepository.getAllEntries(userId);
      state = state.copyWith(
        entries: entries,
        isLoading: false,
        lastSyncedAt: DateTime.now(),
        syncMessage: download.remoteCount == 0
            ? 'No hay notas en la nube. Usa el mismo email que en Supabase.'
            : '${entries.length} notas cargadas',
        error: null,
      );

      _startAutoSyncTimer();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Crear nueva entrada
  Future<bool> createEntry({
    required String date,
    String title = '',
    String content = '',
    String? categoryId,
  }) async {
    final userId = _ref.read(authViewModelProvider).userId;
    if (userId == null) {
      state = state.copyWith(error: 'Usuario no autenticado');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final entry = DiaryEntryFactory.create(
        userId: userId,
        date: date,
        title: title,
        content: content,
        categoryId: categoryId != null && categoryId.isEmpty ? null : categoryId,
      );

      await _diaryRepository.createEntry(entry);
      state = state.copyWith(isLoading: false);
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

  /// Actualizar entrada existente
  Future<bool> updateEntry(DiaryEntry entry) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _diaryRepository.updateEntry(entry);
      state = state.copyWith(isLoading: false);
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

  /// Eliminar entrada
  Future<bool> deleteEntry(String entryId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _diaryRepository.deleteEntry(entryId);
      state = state.copyWith(isLoading: false);
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

  /// Seleccionar una entrada
  void selectEntry(DiaryEntry entry) {
    state = state.copyWith(selectedEntry: entry);
  }

  /// Limpiar selección
  void clearSelection() {
    state = state.copyWith(selectedEntry: null);
  }

  /// Sincronización manual (misma lógica que la automática).
  Future<void> syncPendingEntries() async {
    try {
      await runAutoSync(showIndicator: true, force: true);
    } catch (e) {
      state = state.copyWith(
        error: 'Error al sincronizar: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  /// Al volver a primer plano o iniciar sesión.
  void onAppResumed() {
    unawaited(runAutoSync(showIndicator: true, force: true));
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider para DiaryViewModel
final diaryViewModelProvider = StateNotifierProvider<DiaryViewModel, DiaryState>((ref) {
  final diaryRepository = getIt<DiaryRepository>();
  final viewModel = DiaryViewModel(diaryRepository, ref);

  ref.onDispose(viewModel.dispose);

  ref.listen<AuthState>(authViewModelProvider, (previous, next) {
    if (!next.isAuthenticated || next.userId == null || next.userId!.isEmpty) {
      viewModel.clearEntries();
      return;
    }

    final shouldReload = previous == null ||
        !previous.isAuthenticated ||
        previous.userId != next.userId;

    if (shouldReload) {
      unawaited(viewModel.reloadEntries());
    }
  });

  return viewModel;
});
