import 'package:drift/drift.dart';

/// Tabla para almacenar entradas del diario localmente
class DiaryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get date => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get audioMarkers => text().withDefault(const Constant('[]'))();
  TextColumn get drawStrokes => text().withDefault(const Constant('[]'))();
  TextColumn get audioFilePath => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  IntColumn get lastUpdated => integer()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  // Organización y ciclo de vida
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get colorValue => integer().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  TextColumn get tasksJson => text().withDefault(const Constant('[]'))();
  TextColumn get linksJson => text().withDefault(const Constant('[]'))();
  TextColumn get attachmentsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  TextColumn get lockPinHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
