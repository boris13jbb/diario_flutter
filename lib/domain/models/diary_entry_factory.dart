import '../models/diary_entry.dart';
import '../models/note_attachment.dart';
import '../models/note_link.dart';
import '../models/note_task.dart';

/// Helper para crear instancias de DiaryEntry
class DiaryEntryFactory {
  /// Crea una nueva entrada con valores por defecto
  static DiaryEntry create({
    required String userId,
    required String date,
    String title = '',
    String content = '',
    String? categoryId,
    bool isPinned = false,
    bool isArchived = false,
    int? colorValue,
    int priority = 0,
    List<String> tags = const [],
    List<NoteTask> tasks = const [],
    List<NoteLink> links = const [],
    List<NoteAttachment> attachments = const [],
    DateTime? reminderAt,
  }) {
    final now = DateTime.now();
    return DiaryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      date: date,
      title: title,
      content: content,
      audioMarkers: const [],
      drawStrokes: const [],
      categoryId: categoryId,
      synced: false,
      lastUpdated: now.millisecondsSinceEpoch,
      createdAt: now,
      updatedAt: now,
      isPinned: isPinned,
      isArchived: isArchived,
      isDeleted: false,
      colorValue: colorValue,
      priority: priority,
      tags: tags,
      tasks: tasks,
      links: links,
      attachments: attachments,
      reminderAt: reminderAt,
    );
  }
}
