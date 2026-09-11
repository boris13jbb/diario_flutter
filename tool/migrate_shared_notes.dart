// ignore_for_file: avoid_print

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diario_flutter/firebase_options.dart';
import 'package:diario_flutter/services/note_share_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

/// Migración idempotente de `shared_notes` UUID → id canónico.
///
/// Por defecto es DRY RUN. No borra legacy. Solo con `--apply` escribe
/// el documento canónico si falta. Nunca ejecutes `--apply` en producción
/// desde esta tarea de hardening.
///
/// Uso:
///   dart run tool/migrate_shared_notes.dart
///   dart run tool/migrate_shared_notes.dart --apply
///   dart run tool/migrate_shared_notes.dart --emulator
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

  var legacy = 0;
  var alreadyMigrated = 0;
  var wouldCreate = 0;
  var created = 0;
  var conflicts = 0;
  var errors = 0;

  print(apply ? 'MODO: APPLY' : 'MODO: DRY RUN (por defecto)');
  print('Documentos en shared_notes: ${snap.docs.length}');

  for (final doc in snap.docs) {
    final data = doc.data();
    final noteId = data['note_id']?.toString() ?? '';
    final email = data['shared_with_email']?.toString() ?? '';
    final ownerId = data['owner_id']?.toString() ?? '';
    final permission = data['permission']?.toString() ?? '';

    if (noteId.isEmpty || email.isEmpty || ownerId.isEmpty) {
      errors++;
      print('ERROR ${doc.id}: faltan campos note_id/email/owner_id');
      continue;
    }

    late final String canonicalId;
    try {
      canonicalId = NoteShareService.accessDocId(noteId, email);
    } catch (e) {
      errors++;
      print('ERROR ${doc.id}: correo no soportado ($e)');
      continue;
    }

    if (doc.id == canonicalId) {
      alreadyMigrated++;
      continue;
    }

    legacy++;
    final canonicalRef = firestore
        .collection(NoteShareService.collection)
        .doc(canonicalId);
    final existing = await canonicalRef.get();

    if (existing.exists) {
      final existingData = existing.data() ?? {};
      final sameOwner = existingData['owner_id']?.toString() == ownerId;
      final sameNote = existingData['note_id']?.toString() == noteId;
      final sameEmail =
          existingData['shared_with_email']?.toString() ==
          email.trim().toLowerCase();
      if (sameOwner && sameNote && sameEmail) {
        alreadyMigrated++;
        print('YA MIGRADO legacy=${doc.id} → $canonicalId');
      } else {
        conflicts++;
        print(
          'CONFLICTO legacy=${doc.id} canónico=$canonicalId '
          'ya existe con datos distintos',
        );
      }
      continue;
    }

    wouldCreate++;
    print(
      'CREARÍA canónico=$canonicalId desde legacy=${doc.id} '
      'permission=$permission',
    );

    if (!apply) continue;

    await canonicalRef.set({
      'note_id': noteId,
      'owner_id': ownerId,
      'shared_with_email': email.trim().toLowerCase(),
      'permission': permission == 'edit' ? 'edit' : 'read',
      'created_at': data['created_at'] ?? FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'migrated_from': doc.id,
    });
    created++;
  }

  print('---');
  print('legacy encontrados: $legacy');
  print('canónicos que se crearían: $wouldCreate');
  print('ya migrados / canónicos: $alreadyMigrated');
  print('conflictos: $conflicts');
  print('errores: $errors');
  if (apply) {
    print('canónicos creados: $created');
  } else {
    print('Ningún documento fue modificado (dry-run).');
  }
}
