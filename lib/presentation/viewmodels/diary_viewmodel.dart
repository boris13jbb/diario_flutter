import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/diary_list_filter.dart';
import '../../../core/constants/sync_config.dart';
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
  final bool isSyncing;
  final DateTime? lastSyncedAt;

  const DiaryState({
    this.isLoading = false,
    this.entries = const [],
    this.selectedEntry,
    this.error,
    this.listFilter = DiaryListFilter.all,
    this.searchQuery = '',
    this.favoriteIds = const {},
    this.isSyncing = false,
    this.lastSyncedAt,
  });

  DiaryState copyWith({
    bool? isLoading,
    List<DiaryEntry>? entries,
    DiaryEntry? selectedEntry,
    String? error,
    DiaryListFilter? listFilter,
    String? searchQuery,
    Set<String>? favoriteIds,
    bool? isSyncing,
    DateTime? lastSyncedAt,
  }) {
    return DiaryState(
      isLoading: isLoading ?? this.isLoading,
      entries: entries ?? this.entries,
      selectedEntry: selectedEntry ?? this.selectedEntry,
      error: error,
      listFilter: listFilter ?? this.listFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

/// ViewModel del diario
class DiaryViewModel extends StateNotifier<DiaryState> {
  final DiaryRepository _diaryRepository;
  final FavoritesService _favoritesService;
  final Ref _ref;

  StreamSubscription<List<DiaryEntry>>? _entriesSubscription;
  Timer? _autoSyncTimer;
  bool _syncInProgress = false;
  DateTime? _lastSyncAttempt;

  DiaryViewModel(
    this._diaryRepository,
    this._ref, [
    FavoritesService? favoritesService,
  ])  : _favoritesService = favoritesService ?? FavoritesService(),
        super(const DiaryState()) {
    _loadEntries();
  }

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
      await _diaryRepository.syncAll(userId);
      state = state.copyWith(
        lastSyncedAt: DateTime.now(),
        isSyncing: false,
      );
    } catch (e) {
      state = state.copyWith(isSyncing: false);
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
      print('No hay usuario autenticado, no se pueden cargar entradas');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _loadFavorites(userId);

      await _diaryRepository.syncAll(userId);
      _lastSyncAttempt = DateTime.now();
      state = state.copyWith(lastSyncedAt: DateTime.now());

      _entriesSubscription?.cancel();
      _entriesSubscription = _diaryRepository.watchEntries(userId).listen((entries) {
        state = state.copyWith(
          entries: entries,
          isLoading: false,
        );
      });

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
    unawaited(runAutoSync(showIndicator: false));
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
    if (!next.isAuthenticated) {
      viewModel.stopAutoSync();
      return;
    }
    if (previous != null &&
        previous.isAuthenticated &&
        previous.userId != null &&
        previous.userId != next.userId) {
      viewModel.stopAutoSync();
      viewModel._loadEntries();
    }
  });

  return viewModel;
});
