import 'package:diario_flutter/data/remote/firestore_category_mapper.dart';
import 'package:diario_flutter/data/repositories/categories_repository.dart';
import 'package:diario_flutter/domain/models/note_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mergeNoteCategories', () {
    const localOnly = NoteCategory(
      id: 'local-1',
      name: 'Local',
      colorValue: 0xFF14B8A6,
    );
    const remoteOnly = NoteCategory(
      id: 'remote-1',
      name: 'Remota',
      colorValue: 0xFFEF4444,
    );
    const sharedLocal = NoteCategory(
      id: 'shared',
      name: 'Vieja local',
      colorValue: 0xFF000000,
    );
    const sharedRemote = NoteCategory(
      id: 'shared',
      name: 'Nueva remota',
      colorValue: 0xFFFFFFFF,
    );

    test('dispositivo vacío recupera categorías remotas', () {
      final merged = mergeNoteCategories(
        local: const [],
        remote: [remoteOnly, sharedRemote],
      );
      expect(merged.map((c) => c.id), containsAll(['remote-1', 'shared']));
      expect(merged.firstWhere((c) => c.id == 'shared').name, 'Nueva remota');
    });

    test('categorías solo locales se conservan para poder subirlas', () {
      final merged = mergeNoteCategories(
        local: [localOnly],
        remote: [remoteOnly],
      );
      expect(merged.map((c) => c.id).toSet(), {'local-1', 'remote-1'});
    });

    test('en conflicto de id gana la remota', () {
      final merged = mergeNoteCategories(
        local: [sharedLocal],
        remote: [sharedRemote],
      );
      expect(merged, hasLength(1));
      expect(merged.single.name, 'Nueva remota');
    });

    test('borrados pendientes no resucitan desde local ni remoto', () {
      final merged = mergeNoteCategories(
        local: [localOnly, sharedLocal],
        remote: [sharedRemote, remoteOnly],
        pendingDeleteIds: {'shared', 'local-1'},
      );
      expect(merged.map((c) => c.id).toSet(), {'remote-1'});
    });
  });

  group('FirestoreCategoryMapper color int32', () {
    test('ARGB con alpha se serializa en rango int32 firmado', () {
      const category = NoteCategory(
        id: '1',
        name: 'Trabajo',
        colorValue: 0xFF14B8A6,
      );
      final map = FirestoreCategoryMapper.toFirestore(category, 'user-1');
      final color = map['color'] as int;
      expect(color, category.colorValue.toSigned(32));
      expect(color, lessThanOrEqualTo(0x7FFFFFFF));
      expect(color.toUnsigned(32), 0xFF14B8A6);
    });
  });
}
