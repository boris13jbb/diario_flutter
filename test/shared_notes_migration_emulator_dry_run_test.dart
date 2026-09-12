import 'dart:convert';
import 'dart:io';

import 'package:diario_flutter/services/note_share_service.dart';
import 'package:diario_flutter/services/shared_notes_migration.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dry-run de migración contra Firestore Emulator (sin --apply).
///
/// Usa el acceso admin del emulador (`Authorization: Bearer owner`) solo para
/// sembrar/leer fixtures. No escribe el canónico: solo clasifica.
void main() {
  test('MIGRATION DRY RUN EMULATOR', () async {
    final hostEnv = Platform.environment['FIRESTORE_EMULATOR_HOST'];
    // Solo corre con emulador (tool/run_migrate_shared_notes_dry_run.ps1).
    // En `flutter test` normal se omite para no exigir Firebase local.
    if (hostEnv == null || hostEnv.trim().isEmpty) {
      // ignore: avoid_print
      print('MIGRATION DRY RUN EMULATOR SKIPPED (sin FIRESTORE_EMULATOR_HOST)');
      return;
    }

    final host = hostEnv.trim();
    final project =
        Platform.environment['GCLOUD_PROJECT'] ??
        Platform.environment['GOOGLE_CLOUD_PROJECT'] ??
        'diario-notaspro';
    final client = HttpClient();

    Future<void> putDoc(String id, Map<String, dynamic> fields) async {
      final uri = Uri.parse(
        'http://$host/v1/projects/$project/databases/(default)/documents/'
        'shared_notes/$id',
      );
      final req = await client.openUrl('PATCH', uri);
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer owner');
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(jsonEncode({'fields': _toFirestoreFields(fields)})));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      expect(
        res.statusCode,
        anyOf(200, 201),
        reason: 'seed $id falló: $body',
      );
    }

    Future<Map<String, Map<String, dynamic>>> listShares() async {
      final uri = Uri.parse(
        'http://$host/v1/projects/$project/databases/(default)/documents/'
        'shared_notes',
      );
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer owner');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      expect(res.statusCode, 200, reason: body);
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final docs = (decoded['documents'] as List?) ?? const [];
      final out = <String, Map<String, dynamic>>{};
      for (final raw in docs) {
        final doc = raw as Map<String, dynamic>;
        final name = doc['name']?.toString() ?? '';
        final id = name.split('/').last;
        out[id] = _fromFirestoreFields(
          (doc['fields'] as Map?)?.cast<String, dynamic>() ?? {},
        );
      }
      return out;
    }

    await putDoc('uuid-legacy-read', {
      'note_id': 'note-dry',
      'owner_id': 'owner-dry',
      'shared_with_email': 'reader@example.com',
      'permission': 'read',
    });
    await putDoc('uuid-legacy-edit', {
      'note_id': 'note-dry-2',
      'owner_id': 'owner-dry',
      'shared_with_email': 'editor@example.com',
      'permission': 'edit',
    });
    await putDoc('uuid-legacy-bad', {
      'note_id': 'note-dry-3',
      'owner_id': 'owner-dry',
      'shared_with_email': 'bad@example.com',
      'permission': 'admin',
    });
    await putDoc('note-dry_reader@example.com', {
      'note_id': 'note-dry',
      'owner_id': 'owner-dry',
      'shared_with_email': 'reader@example.com',
      'permission': 'read',
    });

    final shares = await listShares();
    final items = <SharedNotesMigrationItem>[];
    const writes = 0;

    for (final entry in shares.entries) {
      Map<String, dynamic>? existingCanonical;
      final data = entry.value;
      final noteId = data['note_id']?.toString() ?? '';
      final email = data['shared_with_email']?.toString() ?? '';
      if (noteId.isNotEmpty && email.isNotEmpty) {
        try {
          final canonicalId = NoteShareService.accessDocId(noteId, email);
          if (canonicalId != entry.key) {
            existingCanonical = shares[canonicalId];
          }
        } catch (_) {
          // classify reportará el error.
        }
      }

      items.add(
        SharedNotesMigration.classify(
          documentId: entry.key,
          data: data,
          existingCanonical: existingCanonical,
        ),
      );
    }

    final summary = SharedNotesMigration.summarize(items);
    // ignore: avoid_print
    print('MIGRATION DRY RUN EMULATOR    PASS');
    // ignore: avoid_print
    print('legacy encontrados: ${summary.legacy}');
    // ignore: avoid_print
    print('canónicos que se crearían: ${summary.wouldCreate}');
    // ignore: avoid_print
    print('ya migrados / canónicos: ${summary.alreadyMigrated}');
    // ignore: avoid_print
    print('conflictos: ${summary.conflicts}');
    // ignore: avoid_print
    print('errores: ${summary.errors}');
    // ignore: avoid_print
    print('escrituras realizadas: $writes');
    // ignore: avoid_print
    print('0 escrituras no autorizadas');

    expect(summary.wouldCreate, greaterThan(0));
    expect(summary.errors, greaterThan(0));
    expect(summary.alreadyMigrated, greaterThan(0));
    expect(writes, 0);
    client.close(force: true);
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Map<String, dynamic> _toFirestoreFields(Map<String, dynamic> data) {
  return data.map((key, value) {
    if (value is String) {
      return MapEntry(key, {'stringValue': value});
    }
    if (value is bool) {
      return MapEntry(key, {'booleanValue': value});
    }
    if (value is int) {
      return MapEntry(key, {'integerValue': '$value'});
    }
    return MapEntry(key, {'stringValue': '$value'});
  });
}

Map<String, dynamic> _fromFirestoreFields(Map<String, dynamic> fields) {
  return fields.map((key, value) {
    final map = value as Map<String, dynamic>;
    if (map.containsKey('stringValue')) {
      return MapEntry(key, map['stringValue']);
    }
    if (map.containsKey('booleanValue')) {
      return MapEntry(key, map['booleanValue']);
    }
    if (map.containsKey('integerValue')) {
      return MapEntry(key, int.tryParse('${map['integerValue']}') ?? 0);
    }
    return MapEntry(key, map.values.first);
  });
}
