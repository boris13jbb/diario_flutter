import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/note_attachment.dart';

Future<List<int>> readSourceBytes(String sourcePath) async {
  throw Exception(
    'En web debes pasar los bytes del archivo (selector del navegador).',
  );
}

Future<String> persistAttachmentBytes({
  required String userId,
  required String noteId,
  required String fileName,
  required List<int> bytes,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'att_${userId}_${noteId}_$fileName';
  await prefs.setString(key, base64Encode(bytes));
  return key;
}

Future<String> resolveAttachmentPath(NoteAttachment attachment) async {
  return attachment.relativePath;
}

Future<void> deleteStoredAttachment(NoteAttachment attachment) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(attachment.relativePath);
}

Future<List<int>> readStoredAttachment(NoteAttachment attachment) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(attachment.relativePath);
  if (raw == null || raw.isEmpty) {
    throw Exception('Archivo no encontrado en el navegador');
  }
  final bytes = base64Decode(raw);
  // Ofrece descarga al usuario.
  final blob = html.Blob([Uint8List.fromList(bytes)]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', attachment.fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
  return bytes;
}
