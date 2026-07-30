import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Compartición de notas con permisos de lectura o edición.
class NoteShareService {
  final FirebaseFirestore _firestore;
  static const _uuid = Uuid();
  static const collection = 'shared_notes';

  NoteShareService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> shareNote({
    required String noteId,
    required String ownerId,
    required String sharedWithEmail,
    required String permission, // read | edit
  }) async {
    final email = sharedWithEmail.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Correo inválido');
    }
    if (permission != 'read' && permission != 'edit') {
      throw Exception('Permiso inválido');
    }

    final existing = await _firestore
        .collection(collection)
        .where('note_id', isEqualTo: noteId)
        .where('shared_with_email', isEqualTo: email)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update({
        'permission': permission,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return;
    }

    await _firestore.collection(collection).doc(_uuid.v4()).set({
      'note_id': noteId,
      'owner_id': ownerId,
      'shared_with_email': email,
      'permission': permission,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> listShares(String noteId) async {
    final snap = await _firestore
        .collection(collection)
        .where('note_id', isEqualTo: noteId)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> revokeShare(String shareId) async {
    await _firestore.collection(collection).doc(shareId).delete();
  }

  Future<List<Map<String, dynamic>>> sharesForEmail(String email) async {
    final snap = await _firestore
        .collection(collection)
        .where('shared_with_email', isEqualTo: email.trim().toLowerCase())
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}
