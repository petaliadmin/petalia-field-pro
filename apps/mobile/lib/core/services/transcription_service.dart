import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

class TranscriptionService {
  TranscriptionService() : _speech = SpeechToText();

  final SpeechToText _speech;
  bool _isAvailable = false;

  Future<bool> init() async {
    _isAvailable = await _speech.initialize(
      onError: (e) => print('STT Error: $e'),
      onStatus: (s) => print('STT Status: $s'),
    );
    return _isAvailable;
  }

  void startListening({
    required Function(String) onResult,
    String? localeId,
  }) {
    if (!_isAvailable) return;
    _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      localeId: localeId,
      cancelOnError: true,
      listenMode: ListenMode.dictation,
    );
  }

  void stopListening() {
    _speech.stop();
  }

  bool get isListening => _speech.isListening;
}

final transcriptionServiceProvider = Provider<TranscriptionService>((_) => TranscriptionService());
