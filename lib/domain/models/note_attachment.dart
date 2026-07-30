/// Metadatos de un archivo adjunto (imagen, documento o audio).
class NoteAttachment {
  final String id;
  final String fileName;
  final String relativePath;
  final String mimeType;
  final int sizeBytes;
  final String kind; // image | document | audio | other
  final DateTime createdAt;

  const NoteAttachment({
    required this.id,
    required this.fileName,
    required this.relativePath,
    required this.mimeType,
    required this.sizeBytes,
    required this.kind,
    required this.createdAt,
  });

  factory NoteAttachment.fromJson(Map<String, dynamic> json) {
    return NoteAttachment(
      id: json['id']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      relativePath: json['relative_path']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? 'application/octet-stream',
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      kind: json['kind']?.toString() ?? 'other',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'file_name': fileName,
        'relative_path': relativePath,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
        'kind': kind,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
