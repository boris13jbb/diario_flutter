@TestOn('browser')
library;

import 'package:diario_flutter/data/local/database.dart';
import 'package:diario_flutter/domain/models/diary_entry.dart' as domain;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke de persistencia Drift web: abre la misma conexión real que la app.
/// Se ejecuta solo en navegador (`flutter test --platform=chrome`).
/// No toca Firestore.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('abre AppDatabase web, escribe y lee un registro local', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final entryId = 'web-smoke-$stamp';
    final userId = 'web-smoke-user-$stamp';

    final db = AppDatabase();
    try {
      final version = await db
          .customSelect('SELECT sqlite_version() AS v')
          .get();
      expect(version, isNotEmpty);

      final entry = domain.DiaryEntry(
        id: entryId,
        userId: userId,
        date: '2026-03-28',
        title: 'web-smoke-title-$stamp',
        content: 'web-smoke-content-$stamp',
        lastUpdated: stamp,
        synced: false,
      );

      await db.diaryDao.insertEntry(entry);
      final loaded = await db.diaryDao.getEntryById(entryId);

      expect(loaded, isNotNull);
      expect(loaded!.id, entryId);
      expect(loaded.userId, userId);
      expect(loaded.title, entry.title);
      expect(loaded.content, entry.content);

      await db.diaryDao.deleteEntry(entryId);
    } finally {
      await db.close();
    }
  });
}
