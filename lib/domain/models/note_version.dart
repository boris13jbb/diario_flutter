/// Instantánea histórica de una nota para restauración.
class NoteVersion {
  final String id;
  final String noteId;
  final String userId;
  final String title;
  final String content;
  final String snapshotJson;
  final DateTime createdAt;

  const NoteVersion({
    required this.id,
    required this.noteId,
    required this.userId,
    required this.title,
    required this.content,
    required this.snapshotJson,
    required this.createdAt,
  });

  factory NoteVersion.fromJson(Map<String, dynamic> json) {
    return NoteVersion(
      id: json['id']?.toString() ?? '',
      noteId: json['note_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      snapshotJson: json['snapshot_json']?.toString() ?? '{}',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'note_id': noteId,
        'user_id': userId,
        'title': title,
        'content': content,
        'snapshot_json': snapshotJson,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
