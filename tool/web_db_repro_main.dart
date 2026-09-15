import 'package:diario_flutter/data/local/database.dart';
import 'package:diario_flutter/domain/models/diary_entry.dart' as domain;
import 'package:flutter/material.dart';

/// Entrypoint mínimo para reproducir/abrir Drift web sin UI de la app.
/// Uso: flutter run -d chrome -t tool/web_db_repro_main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String status;
  try {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final db = AppDatabase();
    try {
      final version = await db
          .customSelect('SELECT sqlite_version() AS v')
          .get();
      final entryId = 'repro-$stamp';
      await db.diaryDao.insertEntry(
        domain.DiaryEntry(
          id: entryId,
          userId: 'repro-user',
          date: '2026-03-28',
          title: 'repro',
          content: 'repro-content',
          lastUpdated: stamp,
          synced: false,
        ),
      );
      final loaded = await db.diaryDao.getEntryById(entryId);
      await db.diaryDao.deleteEntry(entryId);
      status =
          'WEB_DB_SMOKE_OK version=${version.first.data['v']} loaded=${loaded?.id}';
    } finally {
      await db.close();
    }
  } catch (error, stack) {
    status = 'WEB_DB_SMOKE_FAIL $error\n$stack';
  }

  // ignore: avoid_print
  print(status);
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SelectableText(status, textAlign: TextAlign.center),
        ),
      ),
    ),
  );
}
