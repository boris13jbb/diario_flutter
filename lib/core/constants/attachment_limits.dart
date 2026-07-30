/// Límites y tipos permitidos para adjuntos.
class AttachmentLimits {
  static const int maxBytes = 10 * 1024 * 1024; // 10 MB

  static const Set<String> allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'pdf',
    'txt',
    'md',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'csv',
    'mp3',
    'wav',
    'm4a',
    'aac',
    'ogg',
  };

  static const Set<String> allowedMimePrefixes = {
    'image/',
    'audio/',
    'text/',
    'application/pdf',
    'application/msword',
    'application/vnd.',
  };

  static String kindFor(String extension, String mimeType) {
    final ext = extension.toLowerCase();
    if (mimeType.startsWith('image/') ||
        {'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(ext)) {
      return 'image';
    }
    if (mimeType.startsWith('audio/') ||
        {'mp3', 'wav', 'm4a', 'aac', 'ogg'}.contains(ext)) {
      return 'audio';
    }
    return 'document';
  }
}
