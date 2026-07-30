import 'package:speech_to_text/speech_to_text.dart';

/// Dictado por voz usando capacidades del dispositivo.
class SpeechDictationService {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;

  bool get isAvailable => _available;
  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    _available = await _speech.initialize();
    return _available;
  }

  Future<void> start({
    required void Function(String text) onResult,
    String localeId = 'es_ES',
  }) async {
    if (!_available) {
      final ok = await initialize();
      if (!ok) throw Exception('El reconocimiento de voz no está disponible');
    }
    await _speech.listen(
      localeId: localeId,
      onResult: (result) {
        if (result.finalResult || result.recognizedWords.isNotEmpty) {
          onResult(result.recognizedWords);
        }
      },
    );
  }

  Future<void> stop() => _speech.stop();
  Future<void> cancel() => _speech.cancel();
}
