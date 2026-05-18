import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/diary_repository.dart';
import '../../../domain/models/diary_entry.dart';
import '../../../domain/models/diary_entry_factory.dart';
import '../../../core/di/service_locator.dart';
import 'auth_viewmodel.dart';

/// Estado del diario
class DiaryState {
  final bool isLoading;
  final List<DiaryEntry> entries;
  final DiaryEntry? selectedEntry;
  final String? error;

  const DiaryState({
    this.isLoading = false,
    this.entries = const [],
    this.selectedEntry,
    this.error,
  });

  DiaryState copyWith({
    bool? isLoading,
    List<DiaryEntry>? entries,
    DiaryEntry? selectedEntry,
    String? error,
  }) {
    return DiaryState(
      isLoading: isLoading ?? this.isLoading,
      entries: entries ?? this.entries,
      selectedEntry: selectedEntry ?? this.selectedEntry,
      error: error,
    );
  }
}

/// ViewModel del diario
class DiaryViewModel extends StateNotifier<DiaryState> {
  final DiaryRepository _diaryRepository;
  final Ref _ref;

  DiaryViewModel(this._diaryRepository, this._ref) : super(const DiaryState()) {
    _loadEntries();
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
      // Primero, intentar descargar entradas desde Supabase
      await _diaryRepository.downloadEntriesFromSupabase(userId);
      
      // Luego, escuchar cambios en la base de datos local
      _diaryRepository.watchEntries(userId).listen((entries) {
        state = state.copyWith(
          entries: entries,
          isLoading: false,
        );
      });
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

  /// Sincronizar entradas pendientes
  Future<void> syncPendingEntries() async {
    final userId = _ref.read(authViewModelProvider).userId;
    if (userId == null || userId.isEmpty) return;
    
    try {
      // Primero descargar desde Supabase
      await _diaryRepository.downloadEntriesFromSupabase(userId);
      // Luego subir las pendientes
      await _diaryRepository.syncPendingEntries();
    } catch (e) {
      state = state.copyWith(
        error: 'Error al sincronizar: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider para DiaryViewModel
final diaryViewModelProvider = StateNotifierProvider<DiaryViewModel, DiaryState>((ref) {
  final diaryRepository = getIt<DiaryRepository>();
  return DiaryViewModel(diaryRepository, ref);
});
