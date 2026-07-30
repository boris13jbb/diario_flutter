import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/models/diary_entry.dart';
import '../domain/models/note_category.dart';
import 'export_file_io.dart' if (dart.library.html) 'export_file_web.dart';

enum NoteExportFormat { markdown, txt, pdf, word }

class _PdfFonts {
  final pw.Font regular;
  final pw.Font bold;

  const _PdfFonts({required this.regular, required this.bold});
}

/// Exportación, impresión y compartición de notas (desktop/móvil y web).
class NoteExportService {
  static const _brandTeal = PdfColor.fromInt(0xFF0F766E);
  static const _muted = PdfColor.fromInt(0xFF64748B);
  static const _line = PdfColor.fromInt(0xFFE2E8F0);
  static const _ink = PdfColor.fromInt(0xFF0F172A);

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

  /// Abre el diálogo nativo de compartir con el archivo en el formato elegido.
  Future<ShareResult> shareEntry(
    DiaryEntry entry, {
    List<NoteCategory> categories = const [],
    NoteExportFormat format = NoteExportFormat.markdown,
    Rect? sharePositionOrigin,
  }) async {
    final title =
        entry.title.trim().isEmpty ? 'Nota NotasPro' : entry.title.trim();
    final text = _toPlainText(entry, categories);
    final path = await exportEntry(
      entry,
      format: format,
      categories: categories,
    );
    final formatLabel = switch (format) {
      NoteExportFormat.markdown => 'Markdown',
      NoteExportFormat.txt => 'TXT',
      NoteExportFormat.pdf => 'PDF',
      NoteExportFormat.word => 'Word',
    };

    // En web la exportación descarga el archivo; compartimos el texto completo.
    if (path.startsWith('descarga:')) {
      return SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: '$title ($formatLabel)',
          title: title,
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    }

    // En nativo: archivo completo + texto completo como respaldo.
    return SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: title,
        title: '$title · $formatLabel',
        files: [XFile(path)],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  Future<String> exportAll(
    List<DiaryEntry> entries, {
    NoteExportFormat format = NoteExportFormat.markdown,
    List<NoteCategory> categories = const [],
  }) async {
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    if (format == NoteExportFormat.pdf) {
      final fonts = await _loadFonts();
      final doc = pw.Document();
      for (final entry in entries) {
        doc.addPage(_buildMultiPage(entry, categories, fonts));
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

  String _displayTitle(DiaryEntry entry) =>
      entry.title.trim().isEmpty ? 'Sin título' : entry.title.trim();

  String _bodyContent(DiaryEntry entry) {
    final body = entry.content.trim();
    if (body.isNotEmpty) return body;
    return '(Esta nota no tiene contenido de texto.)';
  }

  String _priorityLabel(int priority) {
    if (priority <= 0) return 'Normal';
    if (priority == 1) return 'Alta';
    return 'Urgente';
  }

  String _tasksBlock(DiaryEntry entry) {
    if (entry.tasks.isEmpty) return '';
    final lines = entry.tasks.map((t) {
      final mark = t.completed ? '[x]' : '[ ]';
      return '- $mark ${t.title}';
    });
    return '\n## Tareas\n${lines.join('\n')}\n';
  }

  String _linksBlock(DiaryEntry entry) {
    if (entry.links.isEmpty) return '';
    final lines = entry.links.map((l) {
      final label = (l.label ?? "").trim().isEmpty ? l.url : (l.label ?? "");
      return '- $label: ${l.url}';
    });
    return '\n## Enlaces\n${lines.join('\n')}\n';
  }

  String _toMarkdown(DiaryEntry entry, List<NoteCategory> categories) {
    final tags =
        entry.tags.isEmpty ? '—' : entry.tags.map((t) => '#$t').join(' ');
    return '''
# ${_displayTitle(entry)}

- **Fecha:** ${entry.date}
- **Categoría:** ${_categoryName(entry, categories)}
- **Prioridad:** ${_priorityLabel(entry.priority)}
- **Etiquetas:** $tags
- **Actualizado:** ${entry.updatedAt?.toIso8601String() ?? entry.lastUpdated}

---

${_bodyContent(entry)}
${_tasksBlock(entry)}${_linksBlock(entry)}
'''.trim();
  }

  String _toPlainText(DiaryEntry entry, List<NoteCategory> categories) {
    final tags = entry.tags.isEmpty ? '—' : entry.tags.join(', ');
    final buffer = StringBuffer()
      ..writeln(_displayTitle(entry))
      ..writeln('=' * _displayTitle(entry).length.clamp(8, 48))
      ..writeln()
      ..writeln('Fecha: ${entry.date}')
      ..writeln('Categoría: ${_categoryName(entry, categories)}')
      ..writeln('Prioridad: ${_priorityLabel(entry.priority)}')
      ..writeln('Etiquetas: $tags')
      ..writeln(
        'Actualizado: ${entry.updatedAt?.toIso8601String() ?? entry.lastUpdated}',
      )
      ..writeln()
      ..writeln('-' * 40)
      ..writeln()
      ..writeln(_bodyContent(entry));

    if (entry.tasks.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Tareas:')
        ..writeln(
          entry.tasks
              .map((t) => '  ${t.completed ? '[x]' : '[ ]'} ${t.title}')
              .join('\n'),
        );
    }
    if (entry.links.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Enlaces:')
        ..writeln(
          entry.links
              .map((l) {
                final label = (l.label ?? "").trim().isEmpty ? l.url : (l.label ?? "");
                return '  - $label: ${l.url}';
              })
              .join('\n'),
        );
    }
    return buffer.toString().trim();
  }

  String _toWordHtml(DiaryEntry entry, List<NoteCategory> categories) {
    final title = _escapeHtml(_displayTitle(entry));
    final body = _escapeHtml(_bodyContent(entry)).replaceAll('\n', '<br/>');
    final tags = entry.tags.isEmpty
        ? '—'
        : _escapeHtml(entry.tags.join(', '));
    final category = _escapeHtml(_categoryName(entry, categories));
    final tasksHtml = entry.tasks.isEmpty
        ? ''
        : '''
<h2>Tareas</h2>
<ul>
${entry.tasks.map((t) => '<li>${t.completed ? '☑' : '☐'} ${_escapeHtml(t.title)}</li>').join('\n')}
</ul>
''';
    final linksHtml = entry.links.isEmpty
        ? ''
        : '''
<h2>Enlaces</h2>
<ul>
${entry.links.map((l) {
          final label = (l.label ?? "").trim().isEmpty ? l.url : (l.label ?? "");
          return '<li><a href="${_escapeHtml(l.url)}">${_escapeHtml(label)}</a></li>';
        }).join('\n')}
</ul>
''';

    return '''
<html xmlns:o="urn:schemas-microsoft-com:office:office"
      xmlns:w="urn:schemas-microsoft-com:office:word"
      xmlns="http://www.w3.org/TR/REC-html40">
<head>
<meta charset="utf-8">
<title>$title</title>
<style>
  body { font-family: Calibri, Arial, sans-serif; color: #0F172A; margin: 40px; line-height: 1.55; }
  .brand { color: #0F766E; font-size: 12px; letter-spacing: 1px; text-transform: uppercase; font-weight: bold; }
  h1 { font-size: 28px; margin: 8px 0 16px; color: #0F172A; }
  .meta { background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 8px; padding: 14px 16px; margin-bottom: 24px; color: #334155; }
  .meta div { margin: 4px 0; }
  .content { font-size: 15px; white-space: pre-wrap; }
  h2 { color: #0F766E; font-size: 16px; margin-top: 28px; }
  hr { border: none; border-top: 2px solid #0F766E; margin: 18px 0 24px; }
</style>
</head>
<body>
<div class="brand">NotasPro</div>
<h1>$title</h1>
<div class="meta">
  <div><b>Fecha:</b> ${entry.date}</div>
  <div><b>Categoría:</b> $category</div>
  <div><b>Prioridad:</b> ${_priorityLabel(entry.priority)}</div>
  <div><b>Etiquetas:</b> $tags</div>
  <div><b>Actualizado:</b> ${entry.updatedAt?.toIso8601String() ?? entry.lastUpdated}</div>
</div>
<hr/>
<div class="content">$body</div>
$tasksHtml
$linksHtml
</body>
</html>
'''.trim();
  }

  String _escapeHtml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  Future<_PdfFonts> _loadFonts() async {
    // Fuentes embebidas con Unicode (acentos, ñ, …). Helvetica no las soporta.
    final regularData =
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    return _PdfFonts(
      regular: pw.Font.ttf(regularData),
      bold: pw.Font.ttf(boldData),
    );
  }

  Future<List<int>> _buildPdf(
    DiaryEntry entry,
    List<NoteCategory> categories,
  ) async {
    final fonts = await _loadFonts();
    final doc = pw.Document(
      title: _displayTitle(entry),
      author: 'NotasPro',
      creator: 'NotasPro',
    );
    doc.addPage(_buildMultiPage(entry, categories, fonts));
    return doc.save();
  }

  pw.MultiPage _buildMultiPage(
    DiaryEntry entry,
    List<NoteCategory> categories,
    _PdfFonts fonts,
  ) {
    final title = _displayTitle(entry);
    final body = _bodyContent(entry);
    final tags = entry.tags.isEmpty ? '—' : entry.tags.join(', ');
    final category = _categoryName(entry, categories);
    final updated =
        entry.updatedAt?.toIso8601String() ?? entry.lastUpdated.toString();

    final base = pw.TextStyle(
      font: fonts.regular,
      fontSize: 11,
      color: _ink,
      height: 1.45,
      lineSpacing: 2,
    );
    final bold = pw.TextStyle(
      font: fonts.bold,
      fontSize: 11,
      color: _ink,
    );

    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 44, 48, 48),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'NOTASPRO',
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: 10,
                  color: _brandTeal,
                  letterSpacing: 1.2,
                ),
              ),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(
                  font: fonts.regular,
                  fontSize: 9,
                  color: _muted,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(height: 2, color: _brandTeal),
          pw.SizedBox(height: 18),
        ],
      ),
      footer: (context) => pw.Column(
        children: [
          pw.Container(height: 1, color: _line),
          pw.SizedBox(height: 8),
          pw.Text(
            'Exportado desde NotasPro · $title',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 8,
              color: _muted,
            ),
          ),
        ],
      ),
      build: (context) {
        final widgets = <pw.Widget>[
          pw.Text(
            title,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 24,
              color: _ink,
              lineSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF8FAFC),
              border: pw.Border.all(color: _line, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _metaRow('Fecha', entry.date, base, bold),
                _metaRow('Categoría', category, base, bold),
                _metaRow('Prioridad', _priorityLabel(entry.priority), base, bold),
                _metaRow('Etiquetas', tags, base, bold),
                _metaRow('Actualizado', updated, base, bold),
              ],
            ),
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Contenido',
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 12,
              color: _brandTeal,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(height: 1, color: _line),
          pw.SizedBox(height: 12),
          pw.Paragraph(
            text: body,
            style: base.copyWith(fontSize: 12),
          ),
        ];

        if (entry.tasks.isNotEmpty) {
          widgets.addAll([
            pw.SizedBox(height: 18),
            pw.Text(
              'Tareas',
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 12,
                color: _brandTeal,
              ),
            ),
            pw.SizedBox(height: 8),
            ...entry.tasks.map(
              (t) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  '${t.completed ? '☑' : '☐'}  ${t.title}',
                  style: base,
                ),
              ),
            ),
          ]);
        }

        if (entry.links.isNotEmpty) {
          widgets.addAll([
            pw.SizedBox(height: 18),
            pw.Text(
              'Enlaces',
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 12,
                color: _brandTeal,
              ),
            ),
            pw.SizedBox(height: 8),
            ...entry.links.map((l) {
              final label = (l.label ?? "").trim().isEmpty ? l.url : (l.label ?? "");
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('• $label — ${l.url}', style: base),
              );
            }),
          ]);
        }

        return widgets;
      },
    );
  }

  pw.Widget _metaRow(
    String label,
    String value,
    pw.TextStyle base,
    pw.TextStyle bold,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$label: ', style: bold),
            pw.TextSpan(text: value, style: base),
          ],
        ),
      ),
    );
  }
}
