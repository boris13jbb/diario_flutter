import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../core/constants/attachment_limits.dart';
import '../domain/models/note_attachment.dart';
import 'attachment_storage_io.dart'
    if (dart.library.html) 'attachment_storage_web.dart';

/// Gestión de archivos adjuntos con validación de tipo y tamaño.
class AttachmentService {
  static const _uuid = Uuid();

  Future<String> absolutePath(NoteAttachment attachment) =>
      resolveAttachmentPath(attachment);

  Future<NoteAttachment> importFile({
    required String userId,
    required String noteId,
    required String sourcePath,
    required String fileName,
    String? mimeType,
    List<int>? bytes,
  }) async {
    final data = bytes ?? await readSourceBytes(sourcePath);
    if (data.isEmpty) {
      throw Exception('El archivo está vacío');
    }
    if (data.length > AttachmentLimits.maxBytes) {
      throw Exception(
        'El archivo supera el límite de ${AttachmentLimits.maxBytes ~/ (1024 * 1024)} MB',
      );
    }

    final ext = p.extension(fileName).replaceFirst('.', '').toLowerCase();
    if (!AttachmentLimits.allowedExtensions.contains(ext)) {
      throw Exception('Tipo de archivo no permitido: .$ext');
    }

    final mime = (mimeType ?? _guessMime(ext)).toLowerCase();
    final allowedMime = AttachmentLimits.allowedMimePrefixes.any(
      (prefix) => mime.startsWith(prefix),
    );
    if (!allowedMime) {
      throw Exception('Tipo MIME no permitido: $mime');
    }

    final id = _uuid.v4();
    final safeName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final relative = await persistAttachmentBytes(
      userId: userId,
      noteId: noteId,
      fileName: '${id}_$safeName',
      bytes: data,
    );

    return NoteAttachment(
      id: id,
      fileName: safeName,
      relativePath: relative,
      mimeType: mime,
      sizeBytes: data.length,
      kind: AttachmentLimits.kindFor(ext, mime),
      createdAt: DateTime.now().toUtc(),
    );
  }

  Future<void> deleteAttachmentFile(NoteAttachment attachment) =>
      deleteStoredAttachment(attachment);

  Future<List<int>> openAttachmentBytes(NoteAttachment attachment) =>
      readStoredAttachment(attachment);

  String exportMetaJson(List<NoteAttachment> attachments) =>
      jsonEncode(attachments.map((a) => a.toJson()).toList());

  String _guessMime(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
      case 'md':
      case 'csv':
        return 'text/plain';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
      case 'aac':
        return 'audio/mp4';
      case 'ogg':
        return 'audio/ogg';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
