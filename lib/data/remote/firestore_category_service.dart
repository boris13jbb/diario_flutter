import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/note_category.dart';
import 'firestore_category_mapper.dart';

/// CRUD de categorías de notas en Cloud Firestore.
class FirestoreCategoryService {
  final FirebaseFirestore _firestore;

  FirestoreCategoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCategoryMapper.collection);

  Future<List<NoteCategory>> getAllForUser(String userId) async {
    try {
      final snapshot = await _collection
          .where('user_id', isEqualTo: userId)
          .orderBy('name')
          .get();

      final categories = <NoteCategory>[];
      for (final doc in snapshot.docs) {
        final category = FirestoreCategoryMapper.fromDocument(doc);
        if (category != null && category.name.isNotEmpty) {
          categories.add(category);
        }
      }
      return categories;
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        return _getAllWithoutOrder(userId);
      }
      throw Exception('Error al obtener categorías: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Error al obtener categorías: $e');
    }
  }

  Future<List<NoteCategory>> _getAllWithoutOrder(String userId) async {
    final snapshot =
        await _collection.where('user_id', isEqualTo: userId).get();
    final categories = <NoteCategory>[];
    for (final doc in snapshot.docs) {
      final category = FirestoreCategoryMapper.fromDocument(doc);
      if (category != null && category.name.isNotEmpty) {
        categories.add(category);
      }
    }
    categories.sort((a, b) => a.name.compareTo(b.name));
    return categories;
  }

  Future<NoteCategory> create(NoteCategory category, String userId) async {
    try {
      final data = FirestoreCategoryMapper.toFirestore(category, userId);
      data['created_at'] = FieldValue.serverTimestamp();
      await _collection.doc(category.id).set(data);
      return category;
    } catch (e) {
      throw Exception('Error al crear categoría en la nube: $e');
    }
  }

  Future<void> upsert(NoteCategory category, String userId) async {
    try {
      final data = FirestoreCategoryMapper.toFirestore(category, userId);
      await _collection.doc(category.id).set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error al sincronizar categoría ${category.id}: $e');
    }
  }

  Future<void> delete(String categoryId) async {
    try {
      await _collection.doc(categoryId).delete();
    } catch (e) {
      throw Exception('Error al eliminar categoría: $e');
    }
  }
}
