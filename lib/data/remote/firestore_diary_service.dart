import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/diary_entry.dart';
import 'firestore_diary_mapper.dart';

/// Sincronización de entradas del diario con Cloud Firestore.
class FirestoreDiaryService {
  final FirebaseFirestore _firestore;

  FirestoreDiaryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreDiaryMapper.collection);

  Future<List<DiaryEntry>> getAllEntries(String userId) async {
    try {
      return await _fetchEntriesForUser(userId, withDateOrder: true);
    } on FirebaseException catch (e) {
      // Índice compuesto ausente: reintenta sin orderBy.
      if (e.code == 'failed-precondition') {
        return _fetchEntriesForUser(userId, withDateOrder: false);
      }
      throw Exception('Error al obtener entradas: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Error al obtener entradas: $e');
    }
  }

  Future<List<DiaryEntry>> _fetchEntriesForUser(
    String userId, {
    required bool withDateOrder,
  }) async {
    Query<Map<String, dynamic>> query =
        _collection.where('user_id', isEqualTo: userId);
    if (withDateOrder) {
      query = query.orderBy('date', descending: true);
    }

    final snapshot = await query.get();
    final entries = <DiaryEntry>[];
    for (final doc in snapshot.docs) {
      final entry = FirestoreDiaryMapper.tryFromDocument(doc);
      if (entry != null) {
        entries.add(entry);
      }
    }

    if (!withDateOrder) {
      entries.sort((a, b) => b.date.compareTo(a.date));
    }
    return entries;
  }

  Future<DiaryEntry?> getEntryById(String entryId) async {
    try {
      final doc = await _collection.doc(entryId).get();
      if (!doc.exists) return null;
      return FirestoreDiaryMapper.fromDocument(doc);
    } catch (e) {
      throw Exception('Error al obtener entrada: $e');
    }
  }

  Future<DiaryEntry> createEntry(DiaryEntry entry) async {
    try {
      final data = FirestoreDiaryMapper.toFirestore(entry);
      await _collection.doc(entry.id).set(data);
      final saved = await getEntryById(entry.id);
      return saved ?? entry.copyWith(synced: true);
    } catch (e) {
      throw Exception('Error al crear entrada: $e');
    }
  }

  Future<DiaryEntry> updateEntry(DiaryEntry entry) async {
    try {
      final data = FirestoreDiaryMapper.toFirestore(entry);
      await _collection.doc(entry.id).set(data, SetOptions(merge: true));
      final saved = await getEntryById(entry.id);
      return saved ?? entry.copyWith(synced: true);
    } catch (e) {
      throw Exception('Error al actualizar entrada: $e');
    }
  }

  Future<void> deleteEntry(String entryId) async {
    try {
      await _collection.doc(entryId).delete();
    } catch (e) {
      throw Exception('Error al eliminar entrada: $e');
    }
  }

  Future<List<DiaryEntry>> getEntriesModifiedAfter(
    String userId,
    DateTime lastSync,
  ) async {
    try {
      final snapshot = await _collection
          .where('user_id', isEqualTo: userId)
          .where(
            'updated_at',
            isGreaterThan: Timestamp.fromDate(lastSync.toUtc()),
          )
          .orderBy('updated_at', descending: true)
          .get();

      return snapshot.docs.map(FirestoreDiaryMapper.fromDocument).toList();
    } catch (e) {
      throw Exception('Error al obtener entradas modificadas: $e');
    }
  }
}
