import 'dart:io';

import 'package:diario_flutter/domain/models/diary_entry.dart';
import 'package:diario_flutter/domain/models/note_category.dart';
import 'package:diario_flutter/services/note_export_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PathProviderPlatform.instance = _FakePathProvider();
  });

  const categories = [
    NoteCategory(id: 'c1', name: 'CANCIONES', colorValue: 0xFF14B8A6),
  ];

  final entry = DiaryEntry(
    id: 'n1',
    userId: 'u1',
    date: '2026-07-29',
    title: 'La Mujer Real',
    content:
        '[Intro]\nLínea con acentos: canción, corazón, niño…\n[Verso 1]\nTexto completo de la nota.',
    lastUpdated: 1,
    categoryId: 'c1',
    tags: const ['musica'],
  );

  test('TXT exporta metadatos y cuerpo completo con acentos', () async {
    final service = NoteExportService();
    final path = await service.exportEntry(
      entry,
      format: NoteExportFormat.txt,
      categories: categories,
    );
    final text = await File(path).readAsString();

    expect(text, contains('La Mujer Real'));
    expect(text, contains('CANCIONES'));
    expect(text, contains('canción'));
    expect(text, contains('corazón'));
    expect(text, contains('[Verso 1]'));
    expect(text, contains('Texto completo de la nota.'));
  });

  test('PDF se genera con fuente Unicode y contenido', () async {
    final service = NoteExportService();
    final path = await service.exportEntry(
      entry,
      format: NoteExportFormat.pdf,
      categories: categories,
    );
    final bytes = await File(path).readAsBytes();

    expect(bytes.length, greaterThan(3000));
    expect(path.toLowerCase(), endsWith('.pdf'));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
