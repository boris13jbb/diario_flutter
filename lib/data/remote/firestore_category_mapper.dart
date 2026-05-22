import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/note_category.dart';

/// Conversión entre [NoteCategory] y documentos de Firestore.
class FirestoreCategoryMapper {
  static const String collection = 'note_categories';

  static Map<String, dynamic> toFirestore(NoteCategory category, String userId) {
    return {
      'user_id': userId,
      'name': category.name,
      'color': category.colorValue,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  static NoteCategory? fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return null;

    return NoteCategory(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      colorValue: (data['color'] as num?)?.toInt() ?? 0xFFE8A87C,
    );
  }
}
