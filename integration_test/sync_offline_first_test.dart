import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diario_flutter/data/remote/firestore_diary_service.dart';
import 'package:diario_flutter/domain/models/diary_entry.dart';
import 'package:diario_flutter/domain/models/diary_entry_factory.dart';
import 'package:diario_flutter/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/gated_diary_remote.dart';
import 'support/sync_device.dart';

/// Flujo automático offline-first contra Auth + Firestore Emulator.
///
/// No usa la cuenta real ni el SQLite del usuario. La red de Windows no se
/// corta. `disableNetwork` no modela el pendiente de este repositorio; el
/// corte lo hace [AvailabilityGatedDiaryRemote] y las lecturas de verificación
/// van a un [FirestoreDiaryService] sin gate.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'sincroniza online, persiste, queda pendiente offline y sube al reconectar',
    (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final onlineTitle = 'AUTO_SYNC_ONLINE_$stamp';
      final offlineTitle = 'AUTO_SYNC_OFFLINE_$stamp';
      final onlineContent = 'contenido-online-$stamp';
      final offlineContent = 'contenido-offline-$stamp';
      final missingId = 'AUTO_MISSING_$stamp';

      final harness = await _EmulatorHarness.start();
      final probe = FirestoreDiaryService(
        firestore: FirebaseFirestore.instance,
      );
      final gated = AvailabilityGatedDiaryRemote(probe);
      final root = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}diario_sync_e2e_$stamp',
      );
      await root.create(recursive: true);

      SyncDevice? deviceA;
      SyncDevice? deviceB;
      try {
        final userA = await harness.signUp('sync-a-$stamp@example.local');
        deviceA = await SyncDevice.open(
          file: File('${root.path}${Platform.pathSeparator}user_a.sqlite'),
          remote: gated,
        );

        final onlineId = 'auto-online-$stamp';
        await deviceA.repository.createEntry(
          _note(
            id: onlineId,
            userId: userA.uid,
            title: onlineTitle,
            content: onlineContent,
          ),
        );
        final created = await deviceA.repository.getEntryById(
          onlineId,
          userId: userA.uid,
        );
        expect(created, isNotNull);
        expect(created!.synced, isTrue);
        _pass('ONLINE CREATE        PASS');

        final localOnline = await deviceA.entriesOf(userA.uid);
        expect(
          localOnline.where((entry) => entry.id == onlineId),
          hasLength(1),
        );
        expect(localOnline.singleWhere((e) => e.id == onlineId).synced, isTrue);
        _pass('ONLINE LOCAL         PASS');

        final remoteOnline = await _requireRemote(probe, userA.uid, onlineId);
        expect(remoteOnline.userId, userA.uid);
        expect(remoteOnline.title, onlineTitle);
        expect(remoteOnline.content, onlineContent);
        expect(
          (await probe.getAllEntries(
            userA.uid,
          )).where((entry) => entry.title == onlineTitle),
          hasLength(1),
        );
        _pass('ONLINE REMOTE        PASS');

        await deviceA.reopen();
        final reopenedOnline = await deviceA.repository.getEntryById(
          onlineId,
          userId: userA.uid,
        );
        expect(reopenedOnline, isNotNull);
        expect(reopenedOnline!.title, onlineTitle);
        expect(reopenedOnline.synced, isTrue);
        _pass('ONLINE REOPEN        PASS');

        gated.online = false;
        final offlineId = 'auto-offline-$stamp';
        await deviceA.repository.createEntry(
          _note(
            id: offlineId,
            userId: userA.uid,
            title: offlineTitle,
            content: offlineContent,
          ),
        );
        final localOffline = await deviceA.repository.getEntryById(
          offlineId,
          userId: userA.uid,
        );
        expect(localOffline, isNotNull);
        expect(localOffline!.synced, isFalse);
        expect(localOffline.title, offlineTitle);
        _pass('OFFLINE CREATE       PASS');
        _pass('OFFLINE LOCAL        PASS');

        final stillOnline = await probe.getEntryById(
          onlineId,
          userId: userA.uid,
        );
        expect(stillOnline, isNotNull);
        expect(await probe.getEntryById(offlineId, userId: userA.uid), isNull);
        final offlineSync = await deviceA.repository.syncPendingEntries(
          userId: userA.uid,
        );
        expect(offlineSync.failed, greaterThan(0));
        final stillPending = await deviceA.repository.getEntryById(
          offlineId,
          userId: userA.uid,
        );
        expect(stillPending?.synced, isFalse);
        final afterFailedSync = await deviceA.entriesOf(userA.uid);
        expect(
          pendingSyncError(
            entries: afterFailedSync,
            failedCount: offlineSync.failed,
          ),
          'Quedan ${afterFailedSync.where((e) => !e.synced).length} notas sin sincronizar',
        );
        expect(await probe.getEntryById(offlineId, userId: userA.uid), isNull);
        _pass('OFFLINE PENDING      PASS');

        await deviceA.reopen();
        final reopenedOffline = await deviceA.repository.getEntryById(
          offlineId,
          userId: userA.uid,
        );
        expect(reopenedOffline, isNotNull);
        expect(reopenedOffline!.synced, isFalse);
        expect(reopenedOffline.content, offlineContent);
        _pass('OFFLINE REOPEN       PASS');

        gated.online = true;
        final reconnect = await deviceA.repository.syncAll(userA.uid);
        expect(reconnect.failedCount, 0);
        final syncedOffline = await deviceA.repository.getEntryById(
          offlineId,
          userId: userA.uid,
        );
        expect(syncedOffline?.synced, isTrue);
        _pass('RECONNECT SYNC       PASS');

        final remoteOffline = await _requireRemote(probe, userA.uid, offlineId);
        expect(remoteOffline.userId, userA.uid);
        expect(remoteOffline.title, offlineTitle);
        expect(remoteOffline.content, offlineContent);
        final remoteOfA = await probe.getAllEntries(userA.uid);
        expect(remoteOfA.where((entry) => entry.id == offlineId), hasLength(1));
        expect(
          remoteOfA.where((entry) => entry.title == offlineTitle),
          hasLength(1),
        );
        expect(
          remoteOfA.where((entry) => entry.title == onlineTitle),
          hasLength(1),
        );
        _pass('RECONNECT REMOTE     PASS');
        _pass('NO DUPLICATES        PASS');

        final pending = (await deviceA.entriesOf(
          userA.uid,
        )).where((entry) => !entry.synced).toList();
        expect(pending, isEmpty);
        expect(
          pendingSyncError(
            entries: await deviceA.entriesOf(userA.uid),
            failedCount: 0,
          ),
          isNull,
        );
        _pass('NO PENDING           PASS');

        final snapshotA = (await deviceA.entriesOf(
          userA.uid,
        )).map((entry) => (entry.id, entry.synced, entry.title)).toList();
        await deviceA.close();
        deviceA = null;

        final userB = await harness.signUp('sync-b-$stamp@example.local');
        final gatedB = AvailabilityGatedDiaryRemote(
          FirestoreDiaryService(firestore: FirebaseFirestore.instance),
        );
        deviceB = await SyncDevice.open(
          file: File('${root.path}${Platform.pathSeparator}user_b.sqlite'),
          remote: gatedB,
        );
        final noteBId = 'auto-b-$stamp';
        await deviceB.repository.createEntry(
          _note(
            id: noteBId,
            userId: userB.uid,
            title: 'AUTO_SYNC_B_$stamp',
            content: 'nota-b-$stamp',
          ),
        );
        expect(await probe.getEntryById(onlineId, userId: userB.uid), isNull);
        expect(await probe.getEntryById(offlineId, userId: userB.uid), isNull);
        final remoteB = await probe.getAllEntries(userB.uid);
        expect(remoteB.where((entry) => entry.id == onlineId), isEmpty);
        expect(remoteB.where((entry) => entry.id == offlineId), isEmpty);
        expect(remoteB.where((entry) => entry.id == noteBId), hasLength(1));

        final isolationSync = await deviceB.repository.syncAll(userB.uid);
        expect(isolationSync.failedCount, 0);
        final localB = await deviceB.entriesOf(userB.uid);
        expect(localB.map((entry) => entry.id), [noteBId]);
        expect(localB.single.synced, isTrue);

        final deviceAAgain = await SyncDevice.open(
          file: File('${root.path}${Platform.pathSeparator}user_a.sqlite'),
          remote: gated,
        );
        deviceA = deviceAAgain;
        final afterB = await deviceA.entriesOf(userA.uid);
        expect(
          afterB.map((entry) => (entry.id, entry.synced, entry.title)).toList(),
          snapshotA,
        );
        await harness.signIn(userA);
        expect(await probe.getEntryById(noteBId, userId: userA.uid), isNull);
        final remoteAAfterB = await probe.getAllEntries(userA.uid);
        expect(remoteAAfterB.where((entry) => entry.id == noteBId), isEmpty);
        _pass('USER ISOLATION       PASS');

        expect(await probe.getEntryById(missingId, userId: userA.uid), isNull);
        await _expectLegacyGetDenied(missingId);
        final ownedAgain = await probe.getEntryById(
          onlineId,
          userId: userA.uid,
        );
        expect(ownedAgain?.id, onlineId);
        expect(ownedAgain?.userId, userA.uid);
        _pass('GET ENTRY SCOPED     PASS');
        await deviceA.repository.createEntry(
          _note(
            id: missingId,
            userId: userA.uid,
            title: 'AUTO_MISSING_CREATED_$stamp',
            content: 'creada-despues-$stamp',
          ),
        );
        final createdMissing = await deviceA.repository.getEntryById(
          missingId,
          userId: userA.uid,
        );
        expect(createdMissing?.synced, isTrue);
        final remoteMissing = await _requireRemote(probe, userA.uid, missingId);
        expect(remoteMissing.userId, userA.uid);
        _pass('MISSING ENTRY        PASS');
      } finally {
        await deviceA?.close();
        await deviceB?.close();
        await harness.signOut();
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

DiaryEntry _note({
  required String id,
  required String userId,
  required String title,
  required String content,
}) {
  return DiaryEntryFactory.create(
    userId: userId,
    date: '2026-09-11',
    title: title,
    content: content,
  ).copyWith(id: id);
}

Future<DiaryEntry> _requireRemote(
  FirestoreDiaryService remote,
  String userId,
  String entryId,
) async {
  final entry = await remote.getEntryById(entryId, userId: userId);
  expect(entry, isNotNull, reason: 'Firestore Emulator no tiene $entryId');
  return entry!;
}

/// Reproduce el `get` por id que las reglas rechazan si el documento no existe.
/// No se aplica a producción; la consulta vigente es [FirestoreDiaryService.getEntryById].
Future<void> _expectLegacyGetDenied(String entryId) async {
  Object? error;
  try {
    await FirebaseFirestore.instance
        .collection('diary_entries')
        .doc(entryId)
        .get();
  } catch (caught) {
    error = caught;
  }
  expect(error, isNotNull);
  final text = error.toString();
  expect(
    text.contains('permission-denied') || text.contains('PERMISSION_DENIED'),
    isTrue,
    reason: 'el get inseguro debía fallar, obtuvo: $error',
  );
}

void _pass(String label) {
  // ignore: avoid_print
  print(label);
}

class _EmulatorUser {
  const _EmulatorUser({
    required this.uid,
    required this.email,
    required this.password,
  });

  final String uid;
  final String email;
  final String password;
}

class _EmulatorHarness {
  static const _password = 'emulator-only-sync-test';

  static Future<_EmulatorHarness> start() async {
    final firestore = _endpoint(
      Platform.environment['FIRESTORE_EMULATOR_HOST'],
      fallbackPort: 8085,
    );
    final auth = _endpoint(
      Platform.environment['FIREBASE_AUTH_EMULATOR_HOST'],
      fallbackPort: 9099,
    );

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuth.instance.useAuthEmulator(auth.host, auth.port);
    // No reasignar settings después: pisaría el host del emulador y hablaría
    // con el proyecto real.
    FirebaseFirestore.instance.useFirestoreEmulator(
      firestore.host,
      firestore.port,
    );
    return _EmulatorHarness();
  }

  static ({String host, int port}) _endpoint(
    String? raw, {
    required int fallbackPort,
  }) {
    if (raw == null || raw.isEmpty) {
      return (host: '127.0.0.1', port: fallbackPort);
    }
    final value = raw.replaceFirst('http://', '').replaceFirst('https://', '');
    final parts = value.split(':');
    if (parts.length != 2) {
      return (host: '127.0.0.1', port: fallbackPort);
    }
    return (host: parts[0], port: int.tryParse(parts[1]) ?? fallbackPort);
  }

  Future<_EmulatorUser> signUp(String email) async {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: _password);
    final user = credential.user;
    if (user == null || user.uid.isEmpty) {
      throw StateError('El emulador de Auth no devolvió usuario para $email');
    }
    // getIdToken falla en Windows por el aviso de hilo de firebase_auth.
    // El SDK adjunta el token al crear o iniciar sesión; no hace falta pedirlo.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _EmulatorUser(uid: user.uid, email: email, password: _password);
  }

  Future<void> signIn(_EmulatorUser user) async {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: user.email,
      password: _password,
    );
    if (credential.user == null) {
      throw StateError('No se pudo volver a iniciar sesión de ${user.email}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<void> signOut() => FirebaseAuth.instance.signOut();
}
