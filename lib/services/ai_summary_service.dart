import 'dart:convert';

import 'package:http/http.dart' as http;

/// Resumen de notas mediante IA (opcional y desacoplado).
class AiSummaryService {
  static const apiKey = String.fromEnvironment('AI_API_KEY');
  static const apiUrl = String.fromEnvironment(
    'AI_API_URL',
    defaultValue: 'https://api.openai.com/v1/chat/completions',
  );
  static const model = String.fromEnvironment(
    'AI_MODEL',
    defaultValue: 'gpt-4o-mini',
  );

  bool get isConfigured => apiKey.trim().isNotEmpty;

  Future<String> summarize({
    required String title,
    required String content,
    required bool userConsented,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'Resumen con IA no configurado. Define AI_API_KEY en el entorno.',
      );
    }
    if (!userConsented) {
      throw Exception(
        'Debes aceptar enviar el contenido a un servicio externo de IA.',
      );
    }
    final text = content.trim();
    if (text.isEmpty) {
      throw Exception('La nota no tiene contenido para resumir');
    }

    final clipped = text.length > 6000 ? text.substring(0, 6000) : text;
    final uri = Uri.parse(apiUrl);
    final body = {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content':
              'Eres un asistente que resume notas en español de forma concisa (máx. 5 viñetas).',
        },
        {
          'role': 'user',
          'content': 'Título: $title\n\nContenido:\n$clipped',
        },
      ],
      'temperature': 0.3,
    };

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error IA HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw Exception('Respuesta de IA inválida');
    final choices = decoded['choices'];
    if (choices is List && choices.isNotEmpty) {
      final message = choices.first['message'];
      if (message is Map && message['content'] != null) {
        return message['content'].toString().trim();
      }
    }
    throw Exception('Respuesta de IA inválida');
  }
}
