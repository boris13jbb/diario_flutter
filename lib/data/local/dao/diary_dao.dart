import 'package:drift/drift.dart';
import '../entities/diary_entries_table.dart';
import '../database.dart';
import '../../../domain/models/diary_entry.dart' as domain;

part 'diary_dao.g.dart';

/// Data Access Object para operaciones con entradas del diario
@DriftAccessor(tables: [DiaryEntries])
class DiaryDao extends DatabaseAccessor<AppDatabase> with _$DiaryDaoMixin {
  DiaryDao(super.db);

  /// Obtiene todas las entradas de un usuario ordenadas por fecha
  Future<List<domain.DiaryEntry>> getEntriesByUser(String userId) {
    return (select(diaryEntries)..where((tbl) => tbl.userId.equals(userId)))
        .map((row) => _mapToDomain(row))
        .get();
  }

  /// Stream que emite cambios en las entradas del usuario
  Stream<List<domain.DiaryEntry>> watchEntriesByUser(String userId) {
    return (select(diaryEntries)..where((tbl) => tbl.userId.equals(userId)))
        .map((row) => _mapToDomain(row))
        .watch();
  }

  /// Obtiene una entrada específica por ID
  Future<domain.DiaryEntry?> getEntryById(String entryId) async {
    final result = await (select(diaryEntries)
          ..where((tbl) => tbl.id.equals(entryId)))
        .map((row) => _mapToDomain(row))
        .getSingleOrNull();
    return result;
  }

  /// Inserta una nueva entrada
  Future<int> insertEntry(domain.DiaryEntry entry) {
    return into(diaryEntries).insert(_mapFromDomain(entry));
  }

  /// Actualiza una entrada existente
  Future<bool> updateEntry(domain.DiaryEntry entry) {
    return update(diaryEntries).replace(_mapFromDomain(entry));
  }

  /// Elimina una entrada por ID
  Future<int> deleteEntry(String entryId) {
    return (delete(diaryEntries)..where((tbl) => tbl.id.equals(entryId))).go();
  }

  /// Obtiene entradas no sincronizadas
  Future<List<domain.DiaryEntry>> getUnsyncedEntries() {
    return (select(diaryEntries)..where((tbl) => tbl.synced.equals(false)))
        .map((row) => _mapToDomain(row))
        .get();
  }

  /// Marca una entrada como sincronizada
  Future<void> markAsSynced(String entryId) {
    return (update(diaryEntries)..where((tbl) => tbl.id.equals(entryId)))
        .write(const DiaryEntriesCompanion(synced: Value(true)));
  }

  /// Elimina todas las entradas de un usuario
  Future<int> deleteAllEntriesForUser(String userId) {
    return (delete(diaryEntries)..where((tbl) => tbl.userId.equals(userId))).go();
  }

  /// Elimina entradas locales de otro usuario (p. ej. UID antiguo de Supabase).
  Future<int> deleteEntriesNotForUser(String userId) {
    return (delete(diaryEntries)..where((tbl) => tbl.userId.equals(userId).not()))
        .go();
  }

  /// Mapea de entidad Drift a modelo de dominio
  domain.DiaryEntry _mapToDomain(DiaryEntry row) {
    return domain.DiaryEntry(
      id: row.id,
      userId: row.userId,
      date: row.date,
      title: row.title,
      content: row.content,
      audioMarkers: [], // TODO: Parsear desde JSON
      drawStrokes: [], // TODO: Parsear desde JSON
      audioFilePath: row.audioFilePath,
      categoryId: row.categoryId,
      synced: row.synced,
      lastUpdated: row.lastUpdated,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Mapea de modelo de dominio a entidad Drift
  DiaryEntriesCompanion _mapFromDomain(domain.DiaryEntry entry) {
    return DiaryEntriesCompanion(
      id: Value(entry.id),
      userId: Value(entry.userId),
      date: Value(entry.date),
      title: Value(entry.title),
      content: Value(entry.content),
      audioMarkers: const Value('[]'), // TODO: Convertir a JSON
      drawStrokes: const Value('[]'), // TODO: Convertir a JSON
      audioFilePath: Value(entry.audioFilePath),
      categoryId: Value(entry.categoryId),
      synced: Value(entry.synced),
      lastUpdated: Value(entry.lastUpdated),
      createdAt: Value(entry.createdAt),
      updatedAt: Value(entry.updatedAt),
    );
  }
}
