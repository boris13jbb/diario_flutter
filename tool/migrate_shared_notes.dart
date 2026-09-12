// ignore_for_file: avoid_print

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diario_flutter/firebase_options.dart';
import 'package:diario_flutter/services/note_share_service.dart';
import 'package:diario_flutter/services/shared_notes_migration.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

/// Migración idempotente de `shared_notes` UUID → id canónico.
///
/// Por defecto es DRY RUN. No borra legacy. Solo con `--apply` escribe
/// el documento canónico si falta y el permission es `read`|`edit`.
///
/// En este proyecto `dart run tool/migrate_shared_notes.dart` y
/// `flutter pub run tool/migrate_shared_notes.dart` fallan al compilar por
/// plugins nativos Firebase/FFI. El comando real de verificación en emulador:
///
///   tool\run_migrate_shared_notes_dry_run.ps1
///
/// (ejecuta `flutter test test/shared_notes_migration_emulator_dry_run_test.dart`
/// dentro de `firebase emulators:exec`).
///
/// La lógica pura vive en [SharedNotesMigration] y se cubre con unit tests.
/// Nunca ejecutes `--apply` en producción sin autorización explícita.
Future<void> main(List<String> args) async {
  final apply = args.contains('--apply');
  final useEmulator = args.contains('--emulator');

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (useEmulator) {
    final host =
        Platform.environment['FIRESTORE_EMULATOR_HOST'] ?? '127.0.0.1:8085';
    final parts = host.replaceFirst('http://', '').split(':');
    FirebaseFirestore.instance.useFirestoreEmulator(
      parts.first,
      int.tryParse(parts.length > 1 ? parts[1] : '8085') ?? 8085,
    );
  }

  final firestore = FirebaseFirestore.instance;
  final snap = await firestore.collection(NoteShareService.collection).get();

  print(apply ? 'MODO: APPLY' : 'MODO: DRY RUN (por defecto)');
  print('Documentos en shared_notes: ${snap.docs.length}');

  final classified = <SharedNotesMigrationItem>[];
  var writes = 0;

  for (final doc in snap.docs) {
    final data = doc.data();
    Map<String, dynamic>? existingCanonical;
    final noteId = data['note_id']?.toString() ?? '';
    final email = data['shared_with_email']?.toString() ?? '';
    if (noteId.isNotEmpty && email.isNotEmpty) {
      try {
        final canonicalId = NoteShareService.accessDocId(noteId, email);
        if (doc.id != canonicalId) {
          final existing = await firestore
              .collection(NoteShareService.collection)
              .doc(canonicalId)
              .get();
          if (existing.exists) {
            existingCanonical = existing.data();
          }
        }
      } catch (_) {
        // classify reportará el error de correo.
      }
    }

    final item = SharedNotesMigration.classify(
      documentId: doc.id,
      data: data,
      existingCanonical: existingCanonical,
    );
    classified.add(item);
    print(item.message);

    if (!apply) continue;
    if (item.kind != SharedNotesMigrationKind.wouldCreate) continue;
    final payload = item.payload;
    final canonicalId = item.canonicalId;
    if (payload == null || canonicalId == null) continue;

    await firestore
        .collection(NoteShareService.collection)
        .doc(canonicalId)
        .set({
          ...payload,
          'created_at': data['created_at'] ?? FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
    writes++;
  }

  final summary = SharedNotesMigration.summarize(classified);
  print('---');
  print('legacy encontrados: ${summary.legacy}');
  print('canónicos que se crearían: ${summary.wouldCreate}');
  print('ya migrados / canónicos: ${summary.alreadyMigrated}');
  print('conflictos: ${summary.conflicts}');
  print('errores: ${summary.errors}');
  if (apply) {
    print('canónicos creados: $writes');
  } else {
    print('Ningún documento fue modificado (dry-run).');
    print('escrituras realizadas: 0');
  }

  if (apply && !useEmulator) {
    stderr.writeln(
      'ADVERTENCIA: --apply fuera de emulador requiere autorización explícita.',
    );
  }
}
