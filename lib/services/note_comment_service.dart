import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Comentarios en notas (colaboración básica).
class NoteCommentService {
  final FirebaseFirestore _firestore;
  static const _uuid = Uuid();
  static const collection = 'note_comments';

  NoteCommentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> addComment({
    required String noteId,
    required String userId,
    required String authorEmail,
    required String text,
  }) async {
    final body = text.trim();
    if (body.isEmpty) throw Exception('El comentario no puede estar vacío');

    await _firestore.collection(collection).doc(_uuid.v4()).set({
      'note_id': noteId,
      'user_id': userId,
      'author_email': authorEmail,
      'text': body,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> listComments(String noteId) async {
    final snap = await _firestore
        .collection(collection)
        .where('note_id', isEqualTo: noteId)
        .orderBy('created_at', descending: false)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> deleteComment(String commentId) async {
    await _firestore.collection(collection).doc(commentId).delete();
  }
}
