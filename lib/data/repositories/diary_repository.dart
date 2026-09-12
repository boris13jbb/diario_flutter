import 'package:injectable/injectable.dart';
import '../../domain/models/diary_entry.dart';
import '../../domain/models/note_version.dart';
import '../local/dao/diary_dao.dart';
import '../local/dao/note_versions_dao.dart';
import '../remote/firestore_diary_service.dart';
import '../../services/note_version_service.dart';
import '../../services/activity_log_service.dart';

/// Resultado de descargar entradas desde Firestore.
class DiaryDownloadResult {
  final int remoteCount;
  final int savedCount;
  final int skippedCount;
  final int uploadedCount;
  final int failedCount;

  const DiaryDownloadResult({
    required this.remoteCount,
    required this.savedCount,
    required this.skippedCount,
    this.uploadedCount = 0,
    this.failedCount = 0,
  });
}

/// Qué hacer con una nota local pendiente frente a la copia remota del mismo usuario.
///
/// [remoteOwned] null significa que no hay documento de ese usuario. Eso no es
/// un error de permisos: la nota se crea. Nunca se aplica una nota de otro usuario.
class PendingEntrySyncDecision {
  final bool shouldCreate;
  final bool shouldUpdateRemote;
  final DiaryEntry? remoteToApply;

  const PendingEntrySyncDecision._({
    required this.shouldCreate,
    required this.shouldUpdateRemote,
    this.remoteToApply,
  });

  factory PendingEntrySyncDecision.resolve({
    required DiaryEntry local,
    required DiaryEntry? remoteOwned,
    required bool localIsSameOrNewer,
  }) {
    if (remoteOwned == null || remoteOwned.userId != local.userId) {
      return const PendingEntrySyncDecision._(
        shouldCreate: true,
        shouldUpdateRemote: false,
      );
    }
    if (localIsSameOrNewer) {
      return const PendingEntrySyncDecision._(
        shouldCreate: false,
        shouldUpdateRemote: true,
      );
    }
    return PendingEntrySyncDecision._(
      shouldCreate: false,
      shouldUpdateRemote: false,
      remoteToApply: remoteOwned.copyWith(userId: local.userId, synced: true),
    );
  }
}

/// Repositorio del diario - Combina datos locales y remotos (offline-first + Firestore).
@LazySingleton()
class DiaryRepository {
  final DiaryDao _diaryDao;
  final DiaryRemoteDataSource _remoteService;
  final NoteVersionsDao _versionsDao;
  late final NoteVersionService _versionService;
  final ActivityLogService _activityLog = ActivityLogService();

  DiaryRepository(this._diaryDao, this._remoteService, this._versionsDao) {
    _versionService = NoteVersionService(_versionsDao);
  }

  Future<List<DiaryEntry>> getAllEntries(String userId) async {
    return _diaryDao.getEntriesByUser(userId);
  }

  Stream<List<DiaryEntry>> watchEntries(String userId) {
    return _diaryDao.watchEntriesByUser(userId);
  }

  /// Nota local del usuario. Si el id pertenece a otra cuenta, retorna null.
  Future<DiaryEntry?> getEntryById(
    String entryId, {
    required String userId,
  }) async {
    if (userId.isEmpty) return null;
    final entry = await _diaryDao.getEntryById(entryId);
    if (entry == null || entry.userId != userId) return null;
    return entry;
  }

  Future<void> createEntry(DiaryEntry entry) async {
    await _diaryDao.insertEntry(entry);
    await _activityLog.log(
      userId: entry.userId,
      action: 'note_created',
      noteId: entry.id,
    );

    try {
      await _remoteService.createEntry(entry);
      await _diaryDao.markAsSynced(entry.id);
    } catch (e) {
      // ignore: avoid_print
      print('Error al sincronizar entrada nueva: $e');
    }
  }

  Future<void> updateEntry(
    DiaryEntry entry, {
    bool recordVersion = true,
  }) async {
    final previous = await _diaryDao.getEntryById(entry.id);
    if (previous != null && previous.userId != entry.userId) {
      throw Exception('No se puede cambiar el propietario de la nota');
    }
    if (recordVersion && previous != null) {
      final titleChanged = previous.title != entry.title;
      final contentChanged = previous.content != entry.content;
      if (titleChanged || contentChanged) {
        await _versionService.saveVersion(previous);
      }
    }

    final updatedEntry = entry.copyWithUpdatedTimestamp();
    await _diaryDao.updateEntry(updatedEntry);
    await _activityLog.log(
      userId: updatedEntry.userId,
      action: 'note_updated',
      noteId: updatedEntry.id,
    );

    try {
      await _remoteService.updateEntry(updatedEntry);
      await _diaryDao.markAsSynced(updatedEntry.id);
    } catch (e) {
      // ignore: avoid_print
      print('Error al sincronizar actualización: $e');
    }
  }

  /// Soft-delete: mueve a papelera solo si la nota es del usuario.
  Future<void> softDeleteEntry(String entryId, {required String userId}) async {
    final existing = await getEntryById(entryId, userId: userId);
    if (existing == null) return;
    final trashed = existing.copyWith(
      isDeleted: true,
      deletedAt: DateTime.now().toUtc(),
      isPinned: false,
    );
    await updateEntry(trashed, recordVersion: false);
    await _activityLog.log(
      userId: existing.userId,
      action: 'note_trashed',
      noteId: entryId,
    );
  }

  Future<void> restoreEntry(String entryId, {required String userId}) async {
    final existing = await getEntryById(entryId, userId: userId);
    if (existing == null) return;
    final restored = existing.copyWith(isDeleted: false, deletedAt: null);
    await updateEntry(restored, recordVersion: false);
    await _activityLog.log(
      userId: existing.userId,
      action: 'note_restored',
      noteId: entryId,
    );
  }

  /// Eliminación definitiva local + remota + versiones. Solo del propietario.
  Future<void> hardDeleteEntry(String entryId, {required String userId}) async {
    final existing = await getEntryById(entryId, userId: userId);
    if (existing == null) return;
    await _diaryDao.deleteEntry(entryId);
    await _versionService.deleteForNote(entryId);

    try {
      await _remoteService.deleteEntry(entryId, userId: existing.userId);
    } catch (e) {
      // ignore: avoid_print
      print('Error al eliminar entrada en Firestore: $e');
    }

    await _activityLog.log(
      userId: existing.userId,
      action: 'note_hard_deleted',
      noteId: entryId,
    );
  }

  /// Compatibilidad: delete = soft delete.
  Future<void> deleteEntry(String entryId, {required String userId}) =>
      softDeleteEntry(entryId, userId: userId);

  Future<void> emptyTrash(String userId) async {
    final entries = await _diaryDao.getEntriesByUser(userId);
    for (final entry in entries.where((e) => e.isDeleted)) {
      await hardDeleteEntry(entry.id, userId: userId);
    }
  }

  Future<List<NoteVersion>> getVersions(String noteId) {
    return _versionService.listVersions(noteId);
  }

  Future<DiaryEntry?> restoreFromVersion(NoteVersion version) async {
    final restored = await _versionService.restoreVersion(version);
    if (restored == null) return null;
    final current = await getEntryById(version.noteId, userId: version.userId);
    if (current == null) return null;
    final merged = current.copyWith(
      title: restored.title,
      content: restored.content,
      tags: restored.tags,
      tasks: restored.tasks,
      links: restored.links,
      priority: restored.priority,
      colorValue: restored.colorValue,
      categoryId: restored.categoryId,
    );
    await updateEntry(merged, recordVersion: true);
    return merged;
  }

  /// Sube pendientes del usuario. Devuelve [uploaded, failed].
  Future<({int uploaded, int failed})> syncPendingEntries({
    String? userId,
  }) async {
    var uploaded = 0;
    var failed = 0;
    try {
      final unsyncedEntries = userId == null || userId.isEmpty
          ? await _diaryDao.getUnsyncedEntries()
          : await _diaryDao.getUnsyncedEntriesByUser(userId);

      final remoteByOwner = <String, Map<String, DiaryEntry>>{};
      if (userId != null && userId.isNotEmpty) {
        remoteByOwner[userId] = await _ownedRemoteIndex(userId);
      }

      for (final entry in unsyncedEntries) {
        if (userId != null && userId.isNotEmpty && entry.userId != userId) {
          failed++;
          continue;
        }
        try {
          final remoteIndex = remoteByOwner[entry.userId] ??=
              await _ownedRemoteIndex(entry.userId);
          final remote = remoteIndex[entry.id];
          final decision = PendingEntrySyncDecision.resolve(
            local: entry,
            remoteOwned: remote,
            localIsSameOrNewer:
                remote == null || _localIsSameOrNewer(entry, remote),
          );

          if (decision.shouldCreate) {
            await _remoteService.createEntry(entry);
            await _diaryDao.markAsSynced(entry.id);
            uploaded++;
            continue;
          }

          if (decision.shouldUpdateRemote) {
            await _remoteService.updateEntry(entry);
            await _diaryDao.markAsSynced(entry.id);
            uploaded++;
            continue;
          }

          final remoteToApply = decision.remoteToApply;
          if (remoteToApply == null) {
            failed++;
            continue;
          }
          await _diaryDao.upsertLocal(remoteToApply);
        } catch (e) {
          failed++;
          // ignore: avoid_print
          print('Error al sincronizar entrada ${entry.id}: $e');
        }
      }
    } catch (e) {
      failed++;
      // ignore: avoid_print
      print('Error al sincronizar entradas pendientes: $e');
    }
    return (uploaded: uploaded, failed: failed);
  }

  Future<DiaryDownloadResult> syncAll(String userId) async {
    final pending = await syncPendingEntries(userId: userId);
    final download = await downloadEntriesFromFirestore(userId);
    return DiaryDownloadResult(
      remoteCount: download.remoteCount,
      savedCount: download.savedCount,
      skippedCount: download.skippedCount,
      uploadedCount: pending.uploaded,
      failedCount: pending.failed,
    );
  }

  Future<DiaryDownloadResult> downloadEntriesFromFirestore(
    String userId,
  ) async {
    final remoteEntries = await _remoteService.getAllEntries(userId);

    await _diaryDao.deleteEntriesNotForUser(userId);

    var savedCount = 0;
    var skippedCount = 0;

    for (final remoteEntry in remoteEntries) {
      if (remoteEntry.userId != userId) {
        skippedCount++;
        continue;
      }
      final entryToStore = remoteEntry.copyWith(userId: userId, synced: true);

      try {
        final localEntry = await _diaryDao.getEntryById(remoteEntry.id);

        if (localEntry == null) {
          await _diaryDao.insertEntry(entryToStore);
          savedCount++;
          continue;
        }
        if (localEntry.userId != userId) {
          skippedCount++;
          continue;
        }

        final shouldUpdate = _shouldApplyRemote(localEntry, remoteEntry);

        if (shouldUpdate) {
          await _diaryDao.upsertLocal(entryToStore);
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

    return DiaryDownloadResult(
      remoteCount: remoteEntries.length,
      savedCount: savedCount,
      skippedCount: skippedCount,
    );
  }

  Future<Map<String, DiaryEntry>> _ownedRemoteIndex(String userId) async {
    final index = <String, DiaryEntry>{};
    if (userId.isEmpty) return index;
    for (final remote in await _remoteService.getAllEntries(userId)) {
      if (remote.userId == userId) {
        index[remote.id] = remote;
      }
    }
    return index;
  }

  bool _shouldApplyRemote(DiaryEntry local, DiaryEntry remote) {
    if (local.userId != remote.userId && remote.userId.isNotEmpty) {
      return true;
    }
    return _entryTimestamp(remote) > _entryTimestamp(local);
  }

  bool _localIsSameOrNewer(DiaryEntry local, DiaryEntry remote) {
    return _entryTimestamp(local) >= _entryTimestamp(remote);
  }

  int _entryTimestamp(DiaryEntry entry) {
    if (entry.updatedAt != null) {
      return entry.updatedAt!.millisecondsSinceEpoch;
    }
    if (entry.lastUpdated > 0) return entry.lastUpdated;
    if (entry.createdAt != null) {
      return entry.createdAt!.millisecondsSinceEpoch;
    }
    return 0;
  }

  Future<void> clearUserData(String userId) async {
    await _diaryDao.deleteAllEntriesForUser(userId);
  }

  Future<void> clearCategoryFromEntries(String categoryId) async {
    await _diaryDao.clearCategoryId(categoryId);
    final pending = await _diaryDao.getUnsyncedEntries();
    for (final entry in pending) {
      if (entry.categoryId == null || entry.categoryId!.isEmpty) {
        try {
          await _remoteService.updateEntry(entry);
          await _diaryDao.markAsSynced(entry.id);
        } catch (_) {}
      }
    }
  }
}
