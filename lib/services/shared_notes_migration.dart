import 'package:diario_flutter/services/note_share_service.dart';

/// Resultado de clasificar un documento `shared_notes` legacy vs canónico.
enum SharedNotesMigrationKind {
  alreadyCanonical,
  alreadyMigrated,
  wouldCreate,
  conflict,
  error,
}

class SharedNotesMigrationItem {
  const SharedNotesMigrationItem({
    required this.kind,
    required this.documentId,
    required this.message,
    this.canonicalId,
    this.payload,
  });

  final SharedNotesMigrationKind kind;
  final String documentId;
  final String? canonicalId;
  final String message;

  /// Datos listos para escribir el canónico (solo si [kind] es [wouldCreate]).
  final Map<String, dynamic>? payload;
}

class SharedNotesMigrationSummary {
  const SharedNotesMigrationSummary({
    required this.items,
    required this.legacy,
    required this.wouldCreate,
    required this.alreadyMigrated,
    required this.conflicts,
    required this.errors,
  });

  final List<SharedNotesMigrationItem> items;
  final int legacy;
  final int wouldCreate;
  final int alreadyMigrated;
  final int conflicts;
  final int errors;
}

/// Lógica pura e idempotente de migración UUID → id canónico.
///
/// No escribe en Firestore. El CLI decide dry-run vs `--apply`.
class SharedNotesMigration {
  static const allowedPermissions = {'read', 'edit'};

  /// Clasifica un documento legacy frente a un canónico existente (si lo hay).
  static SharedNotesMigrationItem classify({
    required String documentId,
    required Map<String, dynamic> data,
    Map<String, dynamic>? existingCanonical,
  }) {
    final noteId = data['note_id']?.toString() ?? '';
    final email = data['shared_with_email']?.toString() ?? '';
    final ownerId = data['owner_id']?.toString() ?? '';
    final permission = data['permission']?.toString() ?? '';

    if (noteId.isEmpty || email.isEmpty || ownerId.isEmpty) {
      return SharedNotesMigrationItem(
        kind: SharedNotesMigrationKind.error,
        documentId: documentId,
        message: 'faltan campos note_id/email/owner_id',
      );
    }

    if (!allowedPermissions.contains(permission)) {
      return SharedNotesMigrationItem(
        kind: SharedNotesMigrationKind.error,
        documentId: documentId,
        message: 'permission inválido: $permission',
      );
    }

    late final String canonicalId;
    late final String normalizedEmail;
    try {
      normalizedEmail = NoteShareService.normalizeShareEmail(email);
      canonicalId = NoteShareService.accessDocId(noteId, normalizedEmail);
    } catch (e) {
      return SharedNotesMigrationItem(
        kind: SharedNotesMigrationKind.error,
        documentId: documentId,
        message: 'correo no soportado ($e)',
      );
    }

    if (documentId == canonicalId) {
      return SharedNotesMigrationItem(
        kind: SharedNotesMigrationKind.alreadyCanonical,
        documentId: documentId,
        canonicalId: canonicalId,
        message: 'ya es canónico',
      );
    }

    if (existingCanonical != null) {
      final sameOwner = existingCanonical['owner_id']?.toString() == ownerId;
      final sameNote = existingCanonical['note_id']?.toString() == noteId;
      final sameEmail =
          existingCanonical['shared_with_email']?.toString() == normalizedEmail;
      final samePermission =
          existingCanonical['permission']?.toString() == permission;
      if (sameOwner && sameNote && sameEmail && samePermission) {
        return SharedNotesMigrationItem(
          kind: SharedNotesMigrationKind.alreadyMigrated,
          documentId: documentId,
          canonicalId: canonicalId,
          message: 'YA MIGRADO legacy=$documentId → $canonicalId',
        );
      }
      return SharedNotesMigrationItem(
        kind: SharedNotesMigrationKind.conflict,
        documentId: documentId,
        canonicalId: canonicalId,
        message:
            'CONFLICTO legacy=$documentId canónico=$canonicalId '
            'ya existe con datos distintos',
      );
    }

    return SharedNotesMigrationItem(
      kind: SharedNotesMigrationKind.wouldCreate,
      documentId: documentId,
      canonicalId: canonicalId,
      message:
          'CREARÍA canónico=$canonicalId desde legacy=$documentId '
          'permission=$permission',
      payload: {
        'note_id': noteId,
        'owner_id': ownerId,
        'shared_with_email': normalizedEmail,
        'permission': permission,
        'migrated_from': documentId,
      },
    );
  }

  static SharedNotesMigrationSummary summarize(
    Iterable<SharedNotesMigrationItem> items,
  ) {
    var legacy = 0;
    var wouldCreate = 0;
    var alreadyMigrated = 0;
    var conflicts = 0;
    var errors = 0;
    for (final item in items) {
      switch (item.kind) {
        case SharedNotesMigrationKind.alreadyCanonical:
          alreadyMigrated++;
        case SharedNotesMigrationKind.alreadyMigrated:
          legacy++;
          alreadyMigrated++;
        case SharedNotesMigrationKind.wouldCreate:
          legacy++;
          wouldCreate++;
        case SharedNotesMigrationKind.conflict:
          legacy++;
          conflicts++;
        case SharedNotesMigrationKind.error:
          errors++;
      }
    }
    return SharedNotesMigrationSummary(
      items: List.unmodifiable(items),
      legacy: legacy,
      wouldCreate: wouldCreate,
      alreadyMigrated: alreadyMigrated,
      conflicts: conflicts,
      errors: errors,
    );
  }
}
