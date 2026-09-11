import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Comentarios en `note_comments`.
///
/// El acceso no se decide aquí: las reglas leen `shared_notes`, la misma
/// colección que concede y revoca el compartir.
class NoteCommentService {
  final FirebaseFirestore _firestore;
  static const _uuid = Uuid();
  static const collection = 'note_comments';

  NoteCommentService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> addComment({
    required String noteId,
    required String ownerId,
    required String userId,
    required String authorEmail,
    required String text,
  }) async {
    final body = text.trim();
    if (noteId.trim().isEmpty || ownerId.trim().isEmpty) {
      throw Exception('El comentario debe estar vinculado a una nota');
    }
    if (body.isEmpty) throw Exception('El comentario no puede estar vacío');

    await _firestore.collection(collection).doc(_uuid.v4()).set({
      'note_id': noteId,
      'owner_id': ownerId,
      'user_id': userId,
      'author_email': authorEmail.trim().toLowerCase(),
      'text': body,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Lista comentarios de una nota a la que [userId] tiene acceso.
  /// La consulta exige `note_id` y `owner_id` para no leer comentarios ajenos.
  Future<List<Map<String, dynamic>>> listComments({
    required String noteId,
    required String ownerId,
  }) async {
    if (noteId.isEmpty || ownerId.isEmpty) return const [];
    final snap = await _firestore
        .collection(collection)
        .where('note_id', isEqualTo: noteId)
        .where('owner_id', isEqualTo: ownerId)
        .orderBy('created_at', descending: false)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> deleteComment(String commentId) async {
    await _firestore.collection(collection).doc(commentId).delete();
  }
}
