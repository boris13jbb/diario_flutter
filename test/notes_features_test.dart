import 'package:diario_flutter/domain/models/diary_entry.dart';
import 'package:diario_flutter/domain/models/diary_entry_factory.dart';
import 'package:diario_flutter/domain/models/note_task.dart';
import 'package:diario_flutter/services/pin_hash_service.dart';
import 'package:diario_flutter/services/ai_summary_service.dart';
import 'package:diario_flutter/core/constants/note_priority.dart';
import 'package:diario_flutter/core/constants/attachment_limits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotePriority', () {
    test('clamp limita el rango', () {
      expect(NotePriority.clamp(-1), NotePriority.none);
      expect(NotePriority.clamp(99), NotePriority.high);
      expect(NotePriority.clamp(2), NotePriority.medium);
    });

    test('labels legibles', () {
      expect(NotePriority.label(NotePriority.high), 'Alta');
      expect(NotePriority.label(NotePriority.none), 'Sin prioridad');
    });
  });

  group('PinHashService', () {
    test('hash no guarda el PIN en claro y verifica correctamente', () {
      final hasher = PinHashService();
      final hash = hasher.hashPin(
        '1234',
        noteId: 'note-1',
        userId: 'user-1',
      );
      expect(hash.contains('1234'), isFalse);
      expect(
        hasher.verify(
          pin: '1234',
          noteId: 'note-1',
          userId: 'user-1',
          storedHash: hash,
        ),
        isTrue,
      );
      expect(
        hasher.verify(
          pin: '9999',
          noteId: 'note-1',
          userId: 'user-1',
          storedHash: hash,
        ),
        isFalse,
      );
    });
  });

  group('DiaryEntryFactory', () {
    test('crea nota con flags por defecto seguros', () {
      final entry = DiaryEntryFactory.create(
        userId: 'u1',
        date: '2026-07-29',
        title: 'Prueba',
        content: 'Contenido',
        tags: const ['trabajo'],
        tasks: [
          NoteTask(id: 't1', title: 'Hacer algo'),
        ],
        priority: NotePriority.high,
      );
      expect(entry.isDeleted, isFalse);
      expect(entry.isArchived, isFalse);
      expect(entry.isPinned, isFalse);
      expect(entry.tags, ['trabajo']);
      expect(entry.tasks.first.title, 'Hacer algo');
      expect(entry.priority, NotePriority.high);
      expect(entry.synced, isFalse);
    });

    test('toRemoteMap incluye organización y papelera', () {
      final entry = DiaryEntryFactory.create(
        userId: 'u1',
        date: '2026-07-29',
        title: 'A',
      ).copyWith(isPinned: true, isArchived: false, tags: ['a', 'b']);
      final map = entry.toRemoteMap();
      expect(map['is_pinned'], isTrue);
      expect(map['tags'], ['a', 'b']);
      expect(map['user_id'], 'u1');
    });
  });

  group('AttachmentLimits', () {
    test('clasifica tipos', () {
      expect(AttachmentLimits.kindFor('png', 'image/png'), 'image');
      expect(AttachmentLimits.kindFor('mp3', 'audio/mpeg'), 'audio');
      expect(AttachmentLimits.kindFor('pdf', 'application/pdf'), 'document');
    });

    test('extensiones permitidas incluyen pdf e imágenes', () {
      expect(AttachmentLimits.allowedExtensions.contains('pdf'), isTrue);
      expect(AttachmentLimits.allowedExtensions.contains('jpg'), isTrue);
      expect(AttachmentLimits.allowedExtensions.contains('exe'), isFalse);
    });
  });

  group('AiSummaryService', () {
    test('sin clave no está configurado', () {
      final service = AiSummaryService();
      expect(service.isConfigured, isFalse);
    });
  });
}
