import 'package:drift/drift.dart';
import '../entities/note_versions_table.dart';
import '../database.dart';
import '../../../domain/models/note_version.dart' as domain;

part 'note_versions_dao.g.dart';

@DriftAccessor(tables: [NoteVersions])
class NoteVersionsDao extends DatabaseAccessor<AppDatabase>
    with _$NoteVersionsDaoMixin {
  NoteVersionsDao(super.db);

  Future<void> insertVersion(domain.NoteVersion version) {
    return into(noteVersions).insert(
      NoteVersionsCompanion.insert(
        id: version.id,
        noteId: version.noteId,
        userId: version.userId,
        title: version.title,
        content: version.content,
        snapshotJson: version.snapshotJson,
        createdAt: version.createdAt,
      ),
    );
  }

  Future<List<domain.NoteVersion>> getVersionsForNote(String noteId) {
    return (select(noteVersions)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .map(
          (row) => domain.NoteVersion(
            id: row.id,
            noteId: row.noteId,
            userId: row.userId,
            title: row.title,
            content: row.content,
            snapshotJson: row.snapshotJson,
            createdAt: row.createdAt,
          ),
        )
        .get();
  }

  Future<domain.NoteVersion?> getVersionById(String id) async {
    final row = await (select(noteVersions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return domain.NoteVersion(
      id: row.id,
      noteId: row.noteId,
      userId: row.userId,
      title: row.title,
      content: row.content,
      snapshotJson: row.snapshotJson,
      createdAt: row.createdAt,
    );
  }

  Future<int> deleteVersionsForNote(String noteId) {
    return (delete(noteVersions)..where((t) => t.noteId.equals(noteId))).go();
  }

  Future<void> pruneOldVersions(String noteId, {int keep = 30}) async {
    final all = await getVersionsForNote(noteId);
    if (all.length <= keep) return;
    final toDelete = all.skip(keep).map((v) => v.id).toList();
    for (final id in toDelete) {
      await (delete(noteVersions)..where((t) => t.id.equals(id))).go();
    }
  }
}
