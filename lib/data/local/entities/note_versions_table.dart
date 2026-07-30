import 'package:drift/drift.dart';

/// Historial de versiones locales de notas.
class NoteVersions extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get snapshotJson => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
