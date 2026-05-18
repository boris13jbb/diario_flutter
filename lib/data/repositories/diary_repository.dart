import 'package:injectable/injectable.dart';
import '../../domain/models/diary_entry.dart';
import '../local/dao/diary_dao.dart';
import '../remote/firestore_diary_service.dart';

/// Repositorio del diario - Combina datos locales y remotos (offline-first + Firestore).
@LazySingleton()
class DiaryRepository {
  final DiaryDao _diaryDao;
  final FirestoreDiaryService _remoteService;

  DiaryRepository(this._diaryDao, this._remoteService);

  Future<List<DiaryEntry>> getAllEntries(String userId) async {
    return _diaryDao.getEntriesByUser(userId);
  }

  Stream<List<DiaryEntry>> watchEntries(String userId) {
    return _diaryDao.watchEntriesByUser(userId);
  }

  Future<DiaryEntry?> getEntryById(String entryId) async {
    return _diaryDao.getEntryById(entryId);
  }

  Future<void> createEntry(DiaryEntry entry) async {
    await _diaryDao.insertEntry(entry);

    try {
      await _remoteService.createEntry(entry);
      await _diaryDao.markAsSynced(entry.id);
    } catch (e) {
      print('Error al sincronizar entrada: $e');
    }
  }

  Future<void> updateEntry(DiaryEntry entry) async {
    final updatedEntry = entry.copyWithUpdatedTimestamp();
    await _diaryDao.updateEntry(updatedEntry);

    try {
      await _remoteService.updateEntry(updatedEntry);
      await _diaryDao.markAsSynced(updatedEntry.id);
    } catch (e) {
      print('Error al sincronizar actualización: $e');
    }
  }

  Future<void> deleteEntry(String entryId) async {
    await _diaryDao.deleteEntry(entryId);

    try {
      await _remoteService.deleteEntry(entryId);
    } catch (e) {
      print('Error al eliminar entrada en Firestore: $e');
    }
  }

  Future<void> syncPendingEntries() async {
    try {
      final unsyncedEntries = await _diaryDao.getUnsyncedEntries();
      for (final entry in unsyncedEntries) {
        try {
          final remote = await _remoteService.getEntryById(entry.id);
          if (remote == null) {
            await _remoteService.createEntry(entry);
          } else {
            await _remoteService.updateEntry(entry);
          }
          await _diaryDao.markAsSynced(entry.id);
        } catch (e) {
          print('Error al sincronizar entrada ${entry.id}: $e');
        }
      }
    } catch (e) {
      print('Error al sincronizar entradas pendientes: $e');
    }
  }

  Future<void> syncAll(String userId) async {
    await downloadEntriesFromFirestore(userId);
    await syncPendingEntries();
  }

  Future<void> downloadEntriesFromFirestore(String userId) async {
    try {
      final remoteEntries = await _remoteService.getAllEntries(userId);

      for (final remoteEntry in remoteEntries) {
        final entryToStore = remoteEntry.copyWith(synced: true);
        final localEntry = await _diaryDao.getEntryById(remoteEntry.id);

        if (localEntry == null) {
          await _diaryDao.insertEntry(entryToStore);
        } else {
          final remoteUpdatedAt = remoteEntry.updatedAt;
          final localUpdatedAt = localEntry.updatedAt;

          var shouldUpdate = false;
          if (remoteUpdatedAt != null) {
            if (localUpdatedAt == null) {
              shouldUpdate = true;
            } else {
              shouldUpdate = remoteUpdatedAt.isAfter(localUpdatedAt);
            }
          }

          if (shouldUpdate) {
            await _diaryDao.updateEntry(entryToStore);
          }
        }
      }

      print('Sincronización completada: ${remoteEntries.length} entradas descargadas');
    } catch (e) {
      print('Error al descargar entradas desde Firestore: $e');
    }
  }

  Future<void> clearUserData(String userId) async {
    await _diaryDao.deleteAllEntriesForUser(userId);
  }
}
