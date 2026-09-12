import 'package:diario_flutter/services/shared_notes_migration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SharedNotesMigration', () {
    Map<String, dynamic> legacy({
      required String permission,
      String noteId = 'note-1',
      String ownerId = 'owner-a',
      String email = 'user@example.com',
    }) {
      return {
        'note_id': noteId,
        'owner_id': ownerId,
        'shared_with_email': email,
        'permission': permission,
      };
    }

    test('legacy read conserva read', () {
      final item = SharedNotesMigration.classify(
        documentId: 'uuid-legacy-read',
        data: legacy(permission: 'read'),
      );
      expect(item.kind, SharedNotesMigrationKind.wouldCreate);
      expect(item.payload?['permission'], 'read');
    });

    test('legacy edit conserva edit', () {
      final item = SharedNotesMigration.classify(
        documentId: 'uuid-legacy-edit',
        data: legacy(permission: 'edit'),
      );
      expect(item.kind, SharedNotesMigrationKind.wouldCreate);
      expect(item.payload?['permission'], 'edit');
    });

    test('canónico existente con mismo permission es YA MIGRADO', () {
      final item = SharedNotesMigration.classify(
        documentId: 'uuid-legacy',
        data: legacy(permission: 'edit'),
        existingCanonical: legacy(permission: 'edit'),
      );
      expect(item.kind, SharedNotesMigrationKind.alreadyMigrated);
      expect(item.message, contains('YA MIGRADO'));
    });

    test('canónico existente con permission distinto es CONFLICTO', () {
      final item = SharedNotesMigration.classify(
        documentId: 'uuid-legacy',
        data: legacy(permission: 'edit'),
        existingCanonical: legacy(permission: 'read'),
      );
      expect(item.kind, SharedNotesMigrationKind.conflict);
      expect(item.message, contains('CONFLICTO'));
      expect(item.payload, isNull);
    });

    test('legacy con permission inválido es ERROR y no propone escritura', () {
      for (final bad in ['admin', 'write', 'unknown', '']) {
        final item = SharedNotesMigration.classify(
          documentId: 'uuid-bad-$bad',
          data: legacy(permission: bad),
        );
        expect(item.kind, SharedNotesMigrationKind.error);
        expect(item.payload, isNull);
        expect(item.message, contains('permission inválido'));
      }
    });

    test('resumen dry-run cuenta legacy y errores sin escritura', () {
      final items = [
        SharedNotesMigration.classify(
          documentId: 'uuid-1',
          data: legacy(permission: 'read'),
        ),
        SharedNotesMigration.classify(
          documentId: 'uuid-2',
          data: legacy(permission: 'admin'),
        ),
        SharedNotesMigration.classify(
          documentId: 'note-1_user@example.com',
          data: legacy(permission: 'read'),
        ),
      ];
      final summary = SharedNotesMigration.summarize(items);
      expect(summary.wouldCreate, 1);
      expect(summary.errors, 1);
      expect(summary.alreadyMigrated, 1);
      expect(summary.legacy, 1);
    });
  });
}
