import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/diary_entry.dart';
import 'firestore_diary_mapper.dart';

/// Acceso remoto a notas, siempre acotado al usuario autenticado.
abstract class DiaryRemoteDataSource {
  Future<List<DiaryEntry>> getAllEntries(String userId);

  /// Nota del usuario, o null si no existe para ese usuario.
  /// No debe convertir "no existe" en un error de permisos.
  Future<DiaryEntry?> getEntryById(String entryId, {required String userId});

  Future<DiaryEntry> createEntry(DiaryEntry entry);

  Future<DiaryEntry> updateEntry(DiaryEntry entry);

  Future<void> deleteEntry(String entryId, {required String userId});
}

/// Sincronización de entradas del diario con Cloud Firestore.
class FirestoreDiaryService implements DiaryRemoteDataSource {
  final FirebaseFirestore _firestore;

  FirestoreDiaryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreDiaryMapper.collection);

  @override
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
    Query<Map<String, dynamic>> query = _collection.where(
      'user_id',
      isEqualTo: userId,
    );
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

  /// Busca una nota del usuario sin descargar todas sus entradas.
  ///
  /// Usa `user_id` + [FieldPath.documentId] con `limit(1)`. No usa
  /// `_collection.doc(entryId).get()` ni [getAllEntries].
  ///
  /// Con las reglas actuales, un documento inexistente o de otro usuario hace
  /// que esa consulta acotada responda `permission-denied` (evaluación con
  /// `resource` nulo o no propio). Ese resultado se traduce a `null` porque el
  /// contrato es «nota de [userId] o ausente», no un fallo de autenticación de
  /// listado. Cualquier otro error de Firebase se propaga.
  @override
  Future<DiaryEntry?> getEntryById(
    String entryId, {
    required String userId,
  }) async {
    if (entryId.isEmpty || userId.isEmpty) return null;
    try {
      final snapshot = await _collection
          .where('user_id', isEqualTo: userId)
          .where(FieldPath.documentId, isEqualTo: entryId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final entry = FirestoreDiaryMapper.tryFromDocument(snapshot.docs.first);
      if (entry == null || entry.userId != userId || entry.id != entryId) {
        return null;
      }
      return entry;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return null;
      }
      throw Exception('Error al obtener entrada: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Error al obtener entrada: $e');
    }
  }

  @override
  Future<DiaryEntry> createEntry(DiaryEntry entry) async {
    try {
      _requireOwner(entry);
      final data = FirestoreDiaryMapper.toFirestore(entry);
      await _collection.doc(entry.id).set(data);
      final saved = await getEntryById(entry.id, userId: entry.userId);
      return saved ?? entry.copyWith(synced: true);
    } catch (e) {
      throw Exception('Error al crear entrada: $e');
    }
  }

  @override
  Future<DiaryEntry> updateEntry(DiaryEntry entry) async {
    try {
      _requireOwner(entry);
      final data = FirestoreDiaryMapper.toFirestore(entry);
      await _collection.doc(entry.id).set(data, SetOptions(merge: true));
      final saved = await getEntryById(entry.id, userId: entry.userId);
      return saved ?? entry.copyWith(synced: true);
    } catch (e) {
      throw Exception('Error al actualizar entrada: $e');
    }
  }

  /// Borra solo si la nota pertenece a [userId]. Si no existe, no es un error.
  @override
  Future<void> deleteEntry(String entryId, {required String userId}) async {
    try {
      final owned = await getEntryById(entryId, userId: userId);
      if (owned == null) return;
      await _collection.doc(entryId).delete();
    } catch (e) {
      throw Exception('Error al eliminar entrada: $e');
    }
  }

  void _requireOwner(DiaryEntry entry) {
    if (entry.userId.isEmpty) {
      throw Exception('La nota no tiene propietario');
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
