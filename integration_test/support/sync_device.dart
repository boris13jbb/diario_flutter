import 'dart:io';

import 'package:diario_flutter/data/local/database.dart' hide DiaryEntry;
import 'package:diario_flutter/data/remote/firestore_diary_service.dart';
import 'package:diario_flutter/data/repositories/diary_repository.dart';
import 'package:diario_flutter/domain/models/diary_entry.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Dispositivo local aislado: SQLite propio y el mismo repositorio de producción.
class SyncDevice {
  SyncDevice({required this.file, required this.remote, required this.db})
    : repository = DiaryRepository(db.diaryDao, remote, db.noteVersionsDao);

  final File file;
  final DiaryRemoteDataSource remote;
  AppDatabase db;
  DiaryRepository repository;

  static Future<SyncDevice> open({
    required File file,
    required DiaryRemoteDataSource remote,
  }) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase.connect(NativeDatabase(file));
    return SyncDevice(file: file, remote: remote, db: db);
  }

  /// Cierra y vuelve a abrir el mismo archivo. Sustituye cerrar y reabrir la app.
  Future<void> reopen() async {
    await db.close();
    db = AppDatabase.connect(NativeDatabase(file));
    repository = DiaryRepository(db.diaryDao, remote, db.noteVersionsDao);
  }

  Future<List<DiaryEntry>> entriesOf(String userId) {
    return repository.getAllEntries(userId);
  }

  Future<void> close() => db.close();
}

/// Mismo criterio que [DiaryViewModel.runAutoSync]: pendientes o fallos
/// dejan el error visible, no un éxito silencioso.
String? pendingSyncError({
  required List<DiaryEntry> entries,
  required int failedCount,
}) {
  final pending = entries.where((entry) => !entry.synced).length;
  final unresolved = failedCount > 0 || pending > 0;
  return unresolved ? 'Quedan $pending notas sin sincronizar' : null;
}
