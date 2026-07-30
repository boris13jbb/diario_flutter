import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/models/note_attachment.dart';

Future<List<int>> readSourceBytes(String sourcePath) async {
  final file = File(sourcePath);
  if (!await file.exists()) {
    throw Exception('El archivo no existe');
  }
  return file.readAsBytes();
}

Future<String> persistAttachmentBytes({
  required String userId,
  required String noteId,
  required String fileName,
  required List<int> bytes,
}) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'NotasPro', 'attachments', userId, noteId));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final dest = File(p.join(dir.path, fileName));
  await dest.writeAsBytes(bytes, flush: true);
  return p.relative(dest.path, from: docs.path).replaceAll('\\', '/');
}

Future<String> resolveAttachmentPath(NoteAttachment attachment) async {
  final docs = await getApplicationDocumentsDirectory();
  return p.join(docs.path, attachment.relativePath);
}

Future<void> deleteStoredAttachment(NoteAttachment attachment) async {
  try {
    final path = await resolveAttachmentPath(attachment);
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (_) {}
}

Future<List<int>> readStoredAttachment(NoteAttachment attachment) async {
  final path = await resolveAttachmentPath(attachment);
  final file = File(path);
  if (!await file.exists()) {
    throw Exception('Archivo no encontrado en el dispositivo');
  }
  return file.readAsBytes();
}
