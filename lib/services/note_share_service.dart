import 'package:cloud_firestore/cloud_firestore.dart';

/// Compartición de notas. La única fuente de autorización es `shared_notes`.
///
/// El id del documento es determinista (`nota_correo`) para que las reglas
/// de comentarios puedan comprobar el acceso sin una segunda colección.
class NoteShareService {
  final FirebaseFirestore _firestore;
  static const collection = 'shared_notes';

  /// Id estable de la concesión. Misma fórmula que `shareDocId` en las reglas.
  static String accessDocId(String noteId, String email) {
    final safeEmail = email.trim().toLowerCase().replaceAll('/', '_');
    return '${noteId}_$safeEmail';
  }

  NoteShareService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> shareNote({
    required String noteId,
    required String ownerId,
    required String sharedWithEmail,
    required String permission, // read | edit
  }) async {
    final email = sharedWithEmail.trim().toLowerCase();
    if (noteId.trim().isEmpty || ownerId.trim().isEmpty) {
      throw Exception('La nota y el propietario son obligatorios');
    }
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Correo inválido');
    }
    if (permission != 'read' && permission != 'edit') {
      throw Exception('Permiso inválido');
    }

    final canonicalId = accessDocId(noteId, email);
    final canonical = _firestore.collection(collection).doc(canonicalId);
    final existing = await _firestore
        .collection(collection)
        .where('note_id', isEqualTo: noteId)
        .where('shared_with_email', isEqualTo: email)
        .get();

    final createdAt = existing.docs.isEmpty
        ? FieldValue.serverTimestamp()
        : existing.docs.first.data()['created_at'] ??
              FieldValue.serverTimestamp();

    await canonical.set({
      'note_id': noteId,
      'owner_id': ownerId,
      'shared_with_email': email,
      'permission': permission,
      'created_at': createdAt,
      'updated_at': FieldValue.serverTimestamp(),
    });

    for (final legacy in existing.docs) {
      if (legacy.id == canonicalId) continue;
      await legacy.reference.delete();
    }
  }

  Future<List<Map<String, dynamic>>> listShares(String noteId) async {
    final snap = await _firestore
        .collection(collection)
        .where('note_id', isEqualTo: noteId)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Revoca el documento indicado y, si era un id antiguo, también el canónico.
  Future<void> revokeShare(String shareId) async {
    final ref = _firestore.collection(collection).doc(shareId);
    final snap = await ref.get();
    final data = snap.data();
    if (snap.exists) {
      await ref.delete();
    }
    if (data == null) return;

    final noteId = data['note_id']?.toString() ?? '';
    final email = data['shared_with_email']?.toString() ?? '';
    if (noteId.isEmpty || email.isEmpty) return;

    final canonicalId = accessDocId(noteId, email);
    if (canonicalId == shareId) return;
    await _firestore.collection(collection).doc(canonicalId).delete();
  }

  Future<List<Map<String, dynamic>>> sharesForEmail(String email) async {
    final snap = await _firestore
        .collection(collection)
        .where('shared_with_email', isEqualTo: email.trim().toLowerCase())
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}
