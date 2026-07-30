import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/diary_entry.dart';
import '../domain/models/note_version.dart';
import '../data/local/dao/note_versions_dao.dart';

/// Historial de versiones local + respaldo opcional en Firestore.
class NoteVersionService {
  final NoteVersionsDao _dao;
  final FirebaseFirestore _firestore;
  static const _uuid = Uuid();
  static const _collection = 'note_versions';

  NoteVersionService(this._dao, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveVersion(DiaryEntry beforeChange) async {
    final version = NoteVersion(
      id: _uuid.v4(),
      noteId: beforeChange.id,
      userId: beforeChange.userId,
      title: beforeChange.title,
      content: beforeChange.content,
      snapshotJson: jsonEncode(beforeChange.toRemoteMap()),
      createdAt: DateTime.now().toUtc(),
    );
    await _dao.insertVersion(version);
    await _dao.pruneOldVersions(beforeChange.id);

    try {
      await _firestore.collection(_collection).doc(version.id).set({
        ...version.toJson(),
        'created_at': Timestamp.fromDate(version.createdAt),
      });
    } catch (_) {
      // El historial local es suficiente si falla la nube.
    }
  }

  Future<List<NoteVersion>> listVersions(String noteId) {
    return _dao.getVersionsForNote(noteId);
  }

  Future<DiaryEntry?> restoreVersion(NoteVersion version) async {
    try {
      final map = jsonDecode(version.snapshotJson);
      if (map is! Map) return null;
      return DiaryEntry.fromJson(Map<String, dynamic>.from(map));
    } catch (_) {
      return DiaryEntry(
        id: version.noteId,
        userId: version.userId,
        date: DateTime.now().toIso8601String().split('T')[0],
        title: version.title,
        content: version.content,
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> deleteForNote(String noteId) async {
    await _dao.deleteVersionsForNote(noteId);
    try {
      final snap = await _firestore
          .collection(_collection)
          .where('note_id', isEqualTo: noteId)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}
  }
}
