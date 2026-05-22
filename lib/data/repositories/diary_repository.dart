import 'package:injectable/injectable.dart';
import '../../domain/models/diary_entry.dart';
import '../local/dao/diary_dao.dart';
import '../remote/firestore_diary_service.dart';

/// Resultado de descargar entradas desde Firestore.
class DiaryDownloadResult {
  final int remoteCount;
  final int savedCount;
  final int skippedCount;

  const DiaryDownloadResult({
    required this.remoteCount,
    required this.savedCount,
    required this.skippedCount,
  });
}

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
      // ignore: avoid_print
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
      // ignore: avoid_print
      print('Error al sincronizar actualización: $e');
    }
  }

  Future<void> deleteEntry(String entryId) async {
    await _diaryDao.deleteEntry(entryId);

    try {
      await _remoteService.deleteEntry(entryId);
    } catch (e) {
      // ignore: avoid_print
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
          // ignore: avoid_print
          print('Error al sincronizar entrada ${entry.id}: $e');
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error al sincronizar entradas pendientes: $e');
    }
  }

  Future<void> syncAll(String userId) async {
    await downloadEntriesFromFirestore(userId);
    await syncPendingEntries();
  }

  /// Descarga notas de Firestore y las fusiona en SQLite.
  /// Corrige entradas locales con UID antiguo (Supabase) que impedían verlas en la lista.
  Future<DiaryDownloadResult> downloadEntriesFromFirestore(String userId) async {
    final remoteEntries = await _remoteService.getAllEntries(userId);

    // Limpia caché local de otro usuario (UID Supabase u otra cuenta).
    await _diaryDao.deleteEntriesNotForUser(userId);

    var savedCount = 0;
    var skippedCount = 0;

    for (final remoteEntry in remoteEntries) {
      final entryToStore = remoteEntry.copyWith(
        userId: userId,
        synced: true,
      );

      try {
        final localEntry = await _diaryDao.getEntryById(remoteEntry.id);

        if (localEntry == null) {
          await _diaryDao.insertEntry(entryToStore);
          savedCount++;
          continue;
        }

        final wrongOwner = localEntry.userId != userId;
        final remoteUpdatedAt = remoteEntry.updatedAt;
        final localUpdatedAt = localEntry.updatedAt;

        var shouldUpdate = wrongOwner;
        if (!shouldUpdate && remoteUpdatedAt != null) {
          if (localUpdatedAt == null) {
            shouldUpdate = true;
          } else {
            shouldUpdate = remoteUpdatedAt.isAfter(localUpdatedAt);
          }
        }

        // Notas migradas en Firestore: priorizar remoto si local no estaba sincronizado.
        if (!shouldUpdate && !localEntry.synced) {
          shouldUpdate = true;
        }

        if (shouldUpdate) {
          await _diaryDao.updateEntry(entryToStore);
          savedCount++;
        } else {
          skippedCount++;
        }
      } catch (e) {
        skippedCount++;
        // ignore: avoid_print
        print('Error al guardar entrada ${remoteEntry.id}: $e');
      }
    }

    // ignore: avoid_print
    print(
      'Sincronización: ${remoteEntries.length} remotas, '
      '$savedCount guardadas/actualizadas, $skippedCount sin cambios',
    );

    return DiaryDownloadResult(
      remoteCount: remoteEntries.length,
      savedCount: savedCount,
      skippedCount: skippedCount,
    );
  }

  Future<void> clearUserData(String userId) async {
    await _diaryDao.deleteAllEntriesForUser(userId);
  }
}
