import 'dart:convert';

import 'package:drift/drift.dart';
import '../entities/diary_entries_table.dart';
import '../database.dart';
import '../../../domain/models/audio_marker.dart';
import '../../../domain/models/diary_entry.dart' as domain;
import '../../../domain/models/draw_stroke.dart';
import '../../../domain/models/note_attachment.dart';
import '../../../domain/models/note_link.dart';
import '../../../domain/models/note_task.dart';

part 'diary_dao.g.dart';

/// Data Access Object para operaciones con entradas del diario
@DriftAccessor(tables: [DiaryEntries])
class DiaryDao extends DatabaseAccessor<AppDatabase> with _$DiaryDaoMixin {
  DiaryDao(super.db);

  Future<List<domain.DiaryEntry>> getEntriesByUser(String userId) {
    return (select(diaryEntries)..where((tbl) => tbl.userId.equals(userId)))
        .map((row) => _mapToDomain(row))
        .get();
  }

  Stream<List<domain.DiaryEntry>> watchEntriesByUser(String userId) {
    return (select(diaryEntries)..where((tbl) => tbl.userId.equals(userId)))
        .map((row) => _mapToDomain(row))
        .watch();
  }

  Future<domain.DiaryEntry?> getEntryById(String entryId) async {
    return (select(diaryEntries)..where((tbl) => tbl.id.equals(entryId)))
        .map((row) => _mapToDomain(row))
        .getSingleOrNull();
  }

  Future<int> insertEntry(domain.DiaryEntry entry) {
    return into(diaryEntries).insert(_mapFromDomain(entry));
  }

  Future<bool> updateEntry(domain.DiaryEntry entry) {
    return update(diaryEntries).replace(_mapFromDomain(entry));
  }

  Future<int> deleteEntry(String entryId) {
    return (delete(diaryEntries)..where((tbl) => tbl.id.equals(entryId))).go();
  }

  Future<List<domain.DiaryEntry>> getUnsyncedEntries() {
    return (select(diaryEntries)..where((tbl) => tbl.synced.equals(false)))
        .map((row) => _mapToDomain(row))
        .get();
  }

  Future<List<domain.DiaryEntry>> getUnsyncedEntriesByUser(String userId) {
    return (select(diaryEntries)
          ..where(
            (tbl) => tbl.userId.equals(userId) & tbl.synced.equals(false),
          ))
        .map((row) => _mapToDomain(row))
        .get();
  }

  Future<void> upsertLocal(domain.DiaryEntry entry) async {
    final existing = await getEntryById(entry.id);
    if (existing == null) {
      await insertEntry(entry);
    } else {
      await updateEntry(entry);
    }
  }

  Future<void> markAsSynced(String entryId) {
    return (update(diaryEntries)..where((tbl) => tbl.id.equals(entryId)))
        .write(const DiaryEntriesCompanion(synced: Value(true)));
  }

  Future<int> deleteAllEntriesForUser(String userId) {
    return (delete(diaryEntries)..where((tbl) => tbl.userId.equals(userId)))
        .go();
  }

  Future<int> deleteEntriesNotForUser(String userId) {
    return (delete(diaryEntries)
          ..where((tbl) => tbl.userId.equals(userId).not()))
        .go();
  }

  Future<int> clearCategoryId(String categoryId) async {
    final now = DateTime.now();
    return (update(diaryEntries)
          ..where((tbl) => tbl.categoryId.equals(categoryId)))
        .write(
      DiaryEntriesCompanion(
        categoryId: const Value(null),
        synced: const Value(false),
        lastUpdated: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now),
      ),
    );
  }

  domain.DiaryEntry _mapToDomain(DiaryEntry row) {
    return domain.DiaryEntry(
      id: row.id,
      userId: row.userId,
      date: row.date,
      title: row.title,
      content: row.content,
      audioMarkers: _decodeAudioMarkers(row.audioMarkers),
      drawStrokes: _decodeDrawStrokes(row.drawStrokes),
      audioFilePath: row.audioFilePath,
      categoryId: row.categoryId,
      synced: row.synced,
      lastUpdated: row.lastUpdated,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isPinned: row.isPinned,
      isArchived: row.isArchived,
      isDeleted: row.isDeleted,
      deletedAt: row.deletedAt,
      colorValue: row.colorValue,
      priority: row.priority,
      tags: _decodeStringList(row.tagsJson),
      tasks: _decodeTasks(row.tasksJson),
      links: _decodeLinks(row.linksJson),
      attachments: _decodeAttachments(row.attachmentsJson),
      reminderAt: row.reminderAt,
      lockPinHash: row.lockPinHash,
    );
  }

  DiaryEntriesCompanion _mapFromDomain(domain.DiaryEntry entry) {
    return DiaryEntriesCompanion(
      id: Value(entry.id),
      userId: Value(entry.userId),
      date: Value(entry.date),
      title: Value(entry.title),
      content: Value(entry.content),
      audioMarkers: Value(_encodeAudioMarkers(entry.audioMarkers)),
      drawStrokes: Value(_encodeDrawStrokes(entry.drawStrokes)),
      audioFilePath: Value(entry.audioFilePath),
      categoryId: Value(entry.categoryId),
      synced: Value(entry.synced),
      lastUpdated: Value(entry.lastUpdated),
      createdAt: Value(entry.createdAt),
      updatedAt: Value(entry.updatedAt),
      isPinned: Value(entry.isPinned),
      isArchived: Value(entry.isArchived),
      isDeleted: Value(entry.isDeleted),
      deletedAt: Value(entry.deletedAt),
      colorValue: Value(entry.colorValue),
      priority: Value(entry.priority),
      tagsJson: Value(jsonEncode(entry.tags)),
      tasksJson: Value(jsonEncode(entry.tasks.map((t) => t.toJson()).toList())),
      linksJson: Value(jsonEncode(entry.links.map((l) => l.toJson()).toList())),
      attachmentsJson:
          Value(jsonEncode(entry.attachments.map((a) => a.toJson()).toList())),
      reminderAt: Value(entry.reminderAt),
      lockPinHash: Value(entry.lockPinHash),
    );
  }

  List<AudioMarker> _decodeAudioMarkers(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map((e) => AudioMarker.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<DrawStroke> _decodeDrawStrokes(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map((e) => DrawStroke.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<String> _decodeStringList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  List<NoteTask> _decodeTasks(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => NoteTask.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<NoteLink> _decodeLinks(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => NoteLink.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<NoteAttachment> _decodeAttachments(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => NoteAttachment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  String _encodeAudioMarkers(List<AudioMarker> markers) =>
      jsonEncode(markers.map((m) => m.toJson()).toList());

  String _encodeDrawStrokes(List<DrawStroke> strokes) =>
      jsonEncode(strokes.map((s) => s.toJson()).toList());
}
