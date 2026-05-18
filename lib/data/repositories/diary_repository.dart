import 'package:injectable/injectable.dart';
import '../../domain/models/diary_entry.dart';
import '../local/dao/diary_dao.dart';
import '../remote/supabase_diary_service.dart';

/// Repositorio del diario - Combina datos locales y remotos con estrategia offline-first
@LazySingleton()
class DiaryRepository {
  final DiaryDao _diaryDao;
  final SupabaseDiaryService _supabaseService;

  DiaryRepository(this._diaryDao, this._supabaseService);

  /// Obtiene todas las entradas del usuario (desde local)
  Future<List<DiaryEntry>> getAllEntries(String userId) async {
    return await _diaryDao.getEntriesByUser(userId);
  }

  /// Stream que emite cambios en las entradas del usuario
  Stream<List<DiaryEntry>> watchEntries(String userId) {
    return _diaryDao.watchEntriesByUser(userId);
  }

  /// Obtiene una entrada específica por ID
  Future<DiaryEntry?> getEntryById(String entryId) async {
    return await _diaryDao.getEntryById(entryId);
  }

  /// Crea una nueva entrada (guarda local primero, luego sincroniza)
  Future<void> createEntry(DiaryEntry entry) async {
    // 1. Guardar localmente
    await _diaryDao.insertEntry(entry);

    // 2. Intentar sincronizar con Supabase si hay conexión
    try {
      await _supabaseService.createEntry(entry);
      await _diaryDao.markAsSynced(entry.id);
    } catch (e) {
      // Si falla la sincronización, la entrada queda marcada como no sincronizada
      print('Error al sincronizar entrada: $e');
    }
  }

  /// Actualiza una entrada existente
  Future<void> updateEntry(DiaryEntry entry) async {
    final updatedEntry = entry.copyWithUpdatedTimestamp();

    // 1. Actualizar localmente
    await _diaryDao.updateEntry(updatedEntry);

    // 2. Intentar sincronizar con Supabase
    try {
      await _supabaseService.updateEntry(updatedEntry);
      await _diaryDao.markAsSynced(updatedEntry.id);
    } catch (e) {
      print('Error al sincronizar actualización: $e');
    }
  }

  /// Elimina una entrada
  Future<void> deleteEntry(String entryId) async {
    // 1. Eliminar localmente
    await _diaryDao.deleteEntry(entryId);

    // 2. Eliminar en Supabase
    try {
      await _supabaseService.deleteEntry(entryId);
    } catch (e) {
      print('Error al eliminar entrada en Supabase: $e');
    }
  }

  /// Sincroniza entradas pendientes con Supabase
  Future<void> syncPendingEntries() async {
    try {
      final unsyncedEntries = await _diaryDao.getUnsyncedEntries();
      if (unsyncedEntries.isNotEmpty) {
        await _supabaseService.syncPendingEntries(unsyncedEntries);

        // Marcar todas como sincronizadas
        for (final entry in unsyncedEntries) {
          await _diaryDao.markAsSynced(entry.id);
        }
      }
    } catch (e) {
      print('Error al sincronizar entradas pendientes: $e');
    }
  }

  /// Descarga todas las entradas desde Supabase y las guarda localmente
  Future<void> downloadEntriesFromSupabase(String userId) async {
    try {
      final remoteEntries = await _supabaseService.getAllEntries(userId);
      
      for (final remoteEntry in remoteEntries) {
        // Verificar si la entrada ya existe localmente
        final localEntry = await _diaryDao.getEntryById(remoteEntry.id);
        
        if (localEntry == null) {
          // Si no existe, insertarla
          await _diaryDao.insertEntry(remoteEntry);
        } else {
          // Si existe, actualizar solo si la versión remota es más reciente
          final remoteUpdatedAt = remoteEntry.updatedAt;
          final localUpdatedAt = localEntry.updatedAt;
          
          // Actualizar si la remota tiene updatedAt y es más reciente, o si la local no tiene updatedAt
          bool shouldUpdate = false;
          
          if (remoteUpdatedAt != null) {
            if (localUpdatedAt == null) {
              shouldUpdate = true;
            } else {
              shouldUpdate = remoteUpdatedAt.isAfter(localUpdatedAt);
            }
          }
          
          if (shouldUpdate) {
            await _diaryDao.updateEntry(remoteEntry);
          }
        }
      }
      
      print('Sincronización completada: ${remoteEntries.length} entradas descargadas');
    } catch (e) {
      print('Error al descargar entradas desde Supabase: $e');
    }
  }

  /// Elimina todas las entradas de un usuario (al cerrar sesión)
  Future<void> clearUserData(String userId) async {
    await _diaryDao.deleteAllEntriesForUser(userId);
  }
}
