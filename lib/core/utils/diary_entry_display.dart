import '../../domain/models/diary_entry.dart';

/// Textos legibles para la sección «Información» de una nota.
class DiaryEntryDisplay {
  DiaryEntryDisplay._();

  static const _monthNames = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static String formatLongDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day} de ${_monthNames[local.month - 1]} de ${local.year}, '
        '$hour:$minute';
  }

  static String formatEntryDate(String date) {
    if (date.trim().isEmpty) return 'Sin fecha asignada';
    final parsed = DateTime.tryParse(date);
    if (parsed != null) {
      final local = parsed.toLocal();
      return '${local.day} de ${_monthNames[local.month - 1]} de ${local.year}';
    }
    return date;
  }

  static String textLengthSummary(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 'Sin texto escrito';
    final words =
        trimmed.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).length;
    final wordLabel = words == 1 ? 'palabra' : 'palabras';
    final charLabel = content.length == 1 ? 'carácter' : 'caracteres';
    return '$words $wordLabel · ${content.length} $charLabel';
  }

  static String? attachmentsSummary(DiaryEntry entry) {
    final parts = <String>[];
    if (entry.audioMarkers.isNotEmpty) {
      final n = entry.audioMarkers.length;
      parts.add('$n marcador${n == 1 ? '' : 'es'} de audio');
    }
    if (entry.drawStrokes.isNotEmpty) {
      final n = entry.drawStrokes.length;
      parts.add('$n dibujo${n == 1 ? '' : 's'}');
    }
    if (entry.audioFilePath != null) {
      parts.add('Grabación de voz');
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  static String syncStatusLabel(bool synced) =>
      synced ? 'Guardada en la nube' : 'Pendiente de subir a la nube';

  static String authorLabel(String? email) {
    if (email != null && email.trim().isNotEmpty) return email.trim();
    return 'Tu cuenta';
  }
}
