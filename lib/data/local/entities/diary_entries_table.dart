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

  @override
  Set<Column> get primaryKey => {id};
}
