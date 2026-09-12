import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diario_flutter/data/remote/firestore_diary_service.dart';
import 'package:diario_flutter/domain/models/diary_entry.dart';

/// Capa remota real con un interruptor de red de prueba.
///
/// [FirebaseFirestore.disableNetwork] existe en cloud_firestore 5.6.12, pero no
/// sirve para este repositorio: la documentación dice que las escrituras no
/// fallan, quedan en cola y el `Future` se resuelve al reconectar. El
/// offline-first de [DiaryRepository] solo deja `synced == false` si la
/// llamada remota lanza. Este gate, usado solo en pruebas, provoca ese fallo
/// sin tocar producción. En línea delega en [FirestoreDiaryService], que habla
/// con el emulador.
class AvailabilityGatedDiaryRemote implements DiaryRemoteDataSource {
  AvailabilityGatedDiaryRemote(this.inner);

  final DiaryRemoteDataSource inner;
  bool online = true;

  void _requireOnline() {
    if (online) return;
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
      message: 'The service is currently unavailable.',
    );
  }

  @override
  Future<List<DiaryEntry>> getAllEntries(String userId) async {
    _requireOnline();
    return inner.getAllEntries(userId);
  }

  @override
  Future<DiaryEntry?> getEntryById(
    String entryId, {
    required String userId,
  }) async {
    _requireOnline();
    return inner.getEntryById(entryId, userId: userId);
  }

  @override
  Future<DiaryEntry> createEntry(DiaryEntry entry) async {
    _requireOnline();
    return inner.createEntry(entry);
  }

  @override
  Future<DiaryEntry> updateEntry(DiaryEntry entry) async {
    _requireOnline();
    return inner.updateEntry(entry);
  }

  @override
  Future<void> deleteEntry(String entryId, {required String userId}) async {
    _requireOnline();
    return inner.deleteEntry(entryId, userId: userId);
  }
}
