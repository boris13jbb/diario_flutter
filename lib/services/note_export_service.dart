import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../domain/models/diary_entry.dart';
import '../domain/models/note_category.dart';
import 'export_file_io.dart' if (dart.library.html) 'export_file_web.dart';

enum NoteExportFormat { markdown, txt, pdf, word }

/// Exportación e impresión de notas (desktop/móvil y web).
class NoteExportService {
  Future<String> exportEntry(
    DiaryEntry entry, {
    NoteExportFormat format = NoteExportFormat.markdown,
    List<NoteCategory> categories = const [],
  }) async {
    final name = _fileNameFor(entry, _ext(format));
    switch (format) {
      case NoteExportFormat.markdown:
        return writeExportBytes(
          name,
          utf8.encode(_toMarkdown(entry, categories)),
        );
      case NoteExportFormat.txt:
        return writeExportBytes(
          name,
          utf8.encode(_toPlainText(entry, categories)),
        );
      case NoteExportFormat.word:
        return writeExportBytes(
          name,
          utf8.encode(_toWordHtml(entry, categories)),
        );
      case NoteExportFormat.pdf:
        final bytes = await _buildPdf(entry, categories);
        return writeExportBytes(name, bytes);
    }
  }

  Future<String> exportAll(
    List<DiaryEntry> entries, {
    NoteExportFormat format = NoteExportFormat.markdown,
    List<NoteCategory> categories = const [],
  }) async {
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    if (format == NoteExportFormat.pdf) {
      final doc = pw.Document();
      for (final entry in entries) {
        doc.addPage(_pdfPage(entry, categories));
      }
      final bytes = await doc.save();
      return writeExportBytes('notaspro_export_$stamp.pdf', bytes);
    }

    final buffer = StringBuffer()
      ..writeln(
        format == NoteExportFormat.markdown
            ? '# Exportación NotasPro'
            : 'Exportación NotasPro',
      )
      ..writeln()
      ..writeln('Generado: ${DateTime.now().toIso8601String()}')
      ..writeln('Total: ${entries.length} notas')
      ..writeln();

    for (final entry in entries) {
      buffer
        ..writeln('---')
        ..writeln()
        ..writeln(
          format == NoteExportFormat.markdown
              ? _toMarkdown(entry, categories)
              : format == NoteExportFormat.word
                  ? _toWordHtml(entry, categories)
                  : _toPlainText(entry, categories),
        )
        ..writeln();
    }

    return writeExportBytes(
      'notaspro_export_$stamp.${_ext(format)}',
      utf8.encode(buffer.toString()),
    );
  }

  Future<void> printEntry(
    DiaryEntry entry, {
    List<NoteCategory> categories = const [],
  }) async {
    final bytes = await _buildPdf(entry, categories);
    await Printing.layoutPdf(
      onLayout: (_) async => Uint8List.fromList(bytes),
    );
  }

  Future<String> exportBackupJson(List<DiaryEntry> entries) async {
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final payload = {
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'count': entries.length,
      'entries': entries.map((e) => e.toRemoteMap()).toList(),
    };
    return writeExportBytes(
      'notaspro_backup_$stamp.json',
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );
  }

  String _ext(NoteExportFormat format) => switch (format) {
        NoteExportFormat.txt => 'txt',
        NoteExportFormat.word => 'doc',
        NoteExportFormat.pdf => 'pdf',
        _ => 'md',
      };

  String _fileNameFor(DiaryEntry entry, String ext) {
    final raw = entry.title.trim().isEmpty ? 'sin_titulo' : entry.title.trim();
    final safe = raw
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    final clipped = safe.length > 40 ? safe.substring(0, 40) : safe;
    return '${clipped}_${entry.id}.$ext';
  }

  String _categoryName(DiaryEntry entry, List<NoteCategory> categories) {
    final id = entry.categoryId;
    if (id == null || id.isEmpty) return 'Sin categoría';
    for (final c in categories) {
      if (c.id == id) return c.name;
    }
    return id;
  }

  String _toMarkdown(DiaryEntry entry, List<NoteCategory> categories) {
    final tags =
        entry.tags.isEmpty ? '—' : entry.tags.map((t) => '#$t').join(' ');
    return '''
# ${entry.title.trim().isEmpty ? 'Sin título' : entry.title.trim()}

- Fecha: ${entry.date}
- Categoría: ${_categoryName(entry, categories)}
- Prioridad: ${entry.priority}
- Etiquetas: $tags
- Actualizado: ${entry.updatedAt?.toIso8601String() ?? entry.lastUpdated}

${entry.content.trim()}
'''.trim();
  }

  String _toPlainText(DiaryEntry entry, List<NoteCategory> categories) {
    return '''
${entry.title.trim().isEmpty ? 'Sin título' : entry.title.trim()}
Fecha: ${entry.date}
Categoría: ${_categoryName(entry, categories)}
Prioridad: ${entry.priority}
Etiquetas: ${entry.tags.join(', ')}
Actualizado: ${entry.updatedAt?.toIso8601String() ?? entry.lastUpdated}

${entry.content.trim()}
'''.trim();
  }

  String _toWordHtml(DiaryEntry entry, List<NoteCategory> categories) {
    final title = _escapeHtml(
      entry.title.trim().isEmpty ? 'Sin título' : entry.title.trim(),
    );
    final body = _escapeHtml(entry.content).replaceAll('\n', '<br/>');
    return '''
<html xmlns:o="urn:schemas-microsoft-com:office:office"
      xmlns:w="urn:schemas-microsoft-com:office:word"
      xmlns="http://www.w3.org/TR/REC-html40">
<head><meta charset="utf-8"><title>$title</title></head>
<body>
<h1>$title</h1>
<p><b>Fecha:</b> ${entry.date}<br/>
<b>Categoría:</b> ${_escapeHtml(_categoryName(entry, categories))}<br/>
<b>Etiquetas:</b> ${_escapeHtml(entry.tags.join(', '))}</p>
<p>$body</p>
</body>
</html>
'''.trim();
  }

  String _escapeHtml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  Future<List<int>> _buildPdf(
    DiaryEntry entry,
    List<NoteCategory> categories,
  ) async {
    final doc = pw.Document();
    doc.addPage(_pdfPage(entry, categories));
    return doc.save();
  }

  pw.Page _pdfPage(DiaryEntry entry, List<NoteCategory> categories) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            entry.title.trim().isEmpty ? 'Sin título' : entry.title.trim(),
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Fecha: ${entry.date}'),
          pw.Text('Categoría: ${_categoryName(entry, categories)}'),
          pw.Text('Etiquetas: ${entry.tags.join(', ')}'),
          pw.SizedBox(height: 16),
          pw.Text(entry.content),
        ],
      ),
    );
  }
}
