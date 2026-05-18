import '../models/diary_entry.dart';

/// Helper para crear instancias de DiaryEntry
class DiaryEntryFactory {
  /// Crea una nueva entrada con valores por defecto
  static DiaryEntry create({
    required String userId,
    required String date,
    String title = '',
    String content = '',
  }) {
    final now = DateTime.now();
    return DiaryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      date: date,
      title: title,
      content: content,
      audioMarkers: [],
      drawStrokes: [],
      synced: false,
      lastUpdated: now.millisecondsSinceEpoch,
      createdAt: now,
      updatedAt: now,
    );
  }
}
