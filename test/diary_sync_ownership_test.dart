import 'dart:io';

import 'package:diario_flutter/data/remote/firestore_diary_service.dart';
import 'package:diario_flutter/data/repositories/diary_repository.dart';
import 'package:diario_flutter/domain/models/diary_entry.dart';
import 'package:diario_flutter/domain/models/diary_entry_factory.dart';
import 'package:diario_flutter/services/note_share_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DiaryEntry note({
    required String id,
    required String userId,
    required String title,
    DateTime? updatedAt,
    bool synced = false,
  }) {
    final created = DiaryEntryFactory.create(
      userId: userId,
      date: '2026-09-10',
      title: title,
      content: 'cuerpo',
    );
    return created.copyWith(
      id: id,
      synced: synced,
      updatedAt: updatedAt ?? DateTime.utc(2026, 9, 10, 12),
    );
  }

  group('nota local que aún no existe en Firestore', () {
    test('una nota inexistente se crea después, sin error de permisos', () {
      final local = note(id: 'nueva', userId: 'user-a', title: 'offline');

      final decision = PendingEntrySyncDecision.resolve(
        local: local,
        remoteOwned: null,
        localIsSameOrNewer: true,
      );

      expect(decision.shouldCreate, isTrue);
      expect(decision.shouldUpdateRemote, isFalse);
      expect(decision.remoteToApply, isNull);
    });

    test('no aplica una nota de otro usuario aunque el id coincida', () {
      final local = note(id: 'misma', userId: 'user-a', title: 'mia');
      final foreign = note(id: 'misma', userId: 'user-b', title: 'ajena');

      final decision = PendingEntrySyncDecision.resolve(
        local: local,
        remoteOwned: foreign,
        localIsSameOrNewer: false,
      );

      expect(decision.shouldCreate, isTrue);
      expect(decision.remoteToApply, isNull);
    });
  });

  group('resolución de conflictos', () {
    test('si la local es más nueva, se actualiza la remota', () {
      final local = note(
        id: 'n1',
        userId: 'user-a',
        title: 'local',
        updatedAt: DateTime.utc(2026, 9, 10, 18),
      );
      final remote = note(
        id: 'n1',
        userId: 'user-a',
        title: 'remota',
        updatedAt: DateTime.utc(2026, 9, 10, 10),
        synced: true,
      );

      final decision = PendingEntrySyncDecision.resolve(
        local: local,
        remoteOwned: remote,
        localIsSameOrNewer: true,
      );

      expect(decision.shouldUpdateRemote, isTrue);
      expect(decision.shouldCreate, isFalse);
      expect(decision.remoteToApply, isNull);
    });

    test(
      'si la remota es más nueva, se aplica la remota del mismo usuario',
      () {
        final local = note(
          id: 'n1',
          userId: 'user-a',
          title: 'vieja',
          updatedAt: DateTime.utc(2026, 9, 10, 8),
        );
        final remote = note(
          id: 'n1',
          userId: 'user-a',
          title: 'nube',
          updatedAt: DateTime.utc(2026, 9, 10, 18),
          synced: true,
        );

        final decision = PendingEntrySyncDecision.resolve(
          local: local,
          remoteOwned: remote,
          localIsSameOrNewer: false,
        );

        expect(decision.shouldCreate, isFalse);
        expect(decision.shouldUpdateRemote, isFalse);
        expect(decision.remoteToApply?.title, 'nube');
        expect(decision.remoteToApply?.userId, 'user-a');
        expect(decision.remoteToApply?.synced, isTrue);
      },
    );
  });

  group('reglas de Firestore', () {
    late String rules;

    setUpAll(() {
      rules = File('firestore.rules').readAsStringSync();
    });

    test('no permite leer comentarios de cualquier usuario autenticado', () {
      expect(rules.contains('allow read: if isSignedIn();'), isFalse);
    });

    test('actualizar una nota exige dueño actual y dueño resultante', () {
      expect(
        rules.contains('request.auth.uid == resource.data.user_id') &&
            rules.contains('request.auth.uid == request.resource.data.user_id'),
        isTrue,
      );
    });

    test('no autoriza un get de nota inexistente para cualquier sesión', () {
      expect(rules.contains('resource == null'), isFalse);
    });

    test('la autorización de compartir y de comentarios es shared_notes', () {
      expect(rules.contains('note_share_access'), isFalse);
      expect(rules.contains('documents/shared_notes/'), isTrue);
      expect(rules.contains('match /note_comments/{commentId}'), isTrue);
    });

    test('comentarios quedan vinculados a una nota accesible', () {
      expect(
        rules.contains('canAccessNote(request.resource.data.note_id)'),
        isTrue,
      );
      expect(rules.contains('isAuthorizedOnNote'), isTrue);
      expect(rules.contains("match /note_comments/{commentId}"), isTrue);
    });

    test('categorías y ajustes siguen aislados por usuario', () {
      expect(rules.contains('match /note_categories/{categoryId}'), isTrue);
      expect(rules.contains('match /user_settings/{userId}'), isTrue);
      expect(
        rules.contains(
          'allow read, write: if isSignedIn() && request.auth.uid == userId;',
        ),
        isTrue,
      );
    });
  });

  test('el acceso compartido usa un id determinista por nota y correo', () {
    expect(
      NoteShareService.accessDocId('nota-1', 'Ana@Example.com'),
      'nota-1_ana@example.com',
    );
    expect(
      NoteShareService.accessDocId('nota-1', '  Ana@Example.com  '),
      'nota-1_ana@example.com',
    );
    expect(
      () => NoteShareService.accessDocId('nota-1', 'bad/slash@example.com'),
      throwsA(isA<Exception>()),
    );
    expect(
      NoteShareService.isCanonicalShareId(
        'nota-1_ana@example.com',
        noteId: 'nota-1',
        sharedWithEmail: 'Ana@Example.com',
      ),
      isTrue,
    );
    expect(
      NoteShareService.isCanonicalShareId(
        'uuid-legacy-001',
        noteId: 'nota-1',
        sharedWithEmail: 'ana@example.com',
      ),
      isFalse,
    );
  });

  group('getEntryById no descarga todas las notas', () {
    test(
      'FirestoreDiaryService busca con documentId y user_id, no lista todo',
      () {
        final source = File(
          'lib/data/remote/firestore_diary_service.dart',
        ).readAsStringSync();
        final classStart = source.indexOf('class FirestoreDiaryService');
        expect(classStart, greaterThan(0));
        final methodStart = source.indexOf(
          'Future<DiaryEntry?> getEntryById',
          classStart,
        );
        expect(methodStart, greaterThan(classStart));
        final methodEnd = source.indexOf(
          'Future<DiaryEntry> createEntry',
          methodStart,
        );
        final method = source.substring(methodStart, methodEnd);
        expect(method.contains('FieldPath.documentId'), isTrue);
        expect(method.contains('.limit(1)'), isTrue);
        expect(method.contains('_fetchEntriesForUser'), isFalse);
        expect(method.contains('getAllEntries'), isFalse);
        expect(method.contains('.doc(entryId).get()'), isFalse);
      },
    );

    test('contrato remoto: getEntryById no implica getAllEntries', () async {
      final remote = _CountingRemote(
        entry: note(id: 'solo', userId: 'user-a', title: 'una', synced: true),
      );
      final found = await remote.getEntryById('solo', userId: 'user-a');
      expect(found?.id, 'solo');
      expect(remote.getEntryByIdCalls, 1);
      expect(remote.getAllEntriesCalls, 0);
    });
  });
}

/// Remote de prueba: [getEntryById] no debe implementarse vía [getAllEntries].
class _CountingRemote implements DiaryRemoteDataSource {
  _CountingRemote({this.entry});

  final DiaryEntry? entry;
  int getAllEntriesCalls = 0;
  int getEntryByIdCalls = 0;

  @override
  Future<List<DiaryEntry>> getAllEntries(String userId) async {
    getAllEntriesCalls++;
    return entry == null ? const [] : [entry!];
  }

  @override
  Future<DiaryEntry?> getEntryById(
    String entryId, {
    required String userId,
  }) async {
    getEntryByIdCalls++;
    // Réplica del contrato: búsqueda puntual, sin listar todo.
    if (entry == null) return null;
    if (entry!.id != entryId || entry!.userId != userId) return null;
    return entry;
  }

  @override
  Future<DiaryEntry> createEntry(DiaryEntry entry) =>
      throw UnimplementedError();

  @override
  Future<DiaryEntry> updateEntry(DiaryEntry entry) =>
      throw UnimplementedError();

  @override
  Future<void> deleteEntry(String entryId, {required String userId}) =>
      throw UnimplementedError();
}
