import 'package:drift/drift.dart';
import 'entities/diary_entries_table.dart';
import 'entities/note_versions_table.dart';
import 'dao/diary_dao.dart';
import 'dao/note_versions_dao.dart';
import 'connection/connection.dart';

part 'database.g.dart';

/// Base de datos principal de la aplicación usando Drift
@DriftDatabase(
  tables: [DiaryEntries, NoteVersions],
  daos: [DiaryDao, NoteVersionsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  /// Abre un archivo SQLite concreto.
  ///
  /// La aplicación usa [AppDatabase]. Este constructor existe para pruebas
  /// aisladas que no deben escribir en el diario del usuario.
  AppDatabase.connect(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(diaryEntries, diaryEntries.categoryId);
        }
        if (from < 3) {
          await m.addColumn(diaryEntries, diaryEntries.isPinned);
          await m.addColumn(diaryEntries, diaryEntries.isArchived);
          await m.addColumn(diaryEntries, diaryEntries.isDeleted);
          await m.addColumn(diaryEntries, diaryEntries.deletedAt);
          await m.addColumn(diaryEntries, diaryEntries.colorValue);
          await m.addColumn(diaryEntries, diaryEntries.priority);
          await m.addColumn(diaryEntries, diaryEntries.tagsJson);
          await m.addColumn(diaryEntries, diaryEntries.tasksJson);
          await m.addColumn(diaryEntries, diaryEntries.linksJson);
          await m.addColumn(diaryEntries, diaryEntries.attachmentsJson);
          await m.addColumn(diaryEntries, diaryEntries.reminderAt);
          await m.addColumn(diaryEntries, diaryEntries.lockPinHash);
          await m.createTable(noteVersions);
        }
      },
    );
  }
}
