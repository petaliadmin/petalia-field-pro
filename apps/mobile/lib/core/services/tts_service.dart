import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'settings_service.dart';

/// Text-to-speech service used to read out **critical recommendations**
/// (P4.4) for users who can't comfortably read the screen — common in
/// rural Senegal where literacy in the user's preferred reading language
/// is not guaranteed.
///
/// ## Locale strategy
///
/// Native TTS engines (Android `TextToSpeech`, iOS `AVSpeechSynthesizer`)
/// ship voices for the world's major languages. **Wolof and Pulaar are
/// not available on any consumer device** as of 2026 — you can confirm
/// the catalog with `getLanguages` at runtime.
///
/// Choices we considered :
/// 1. **Skip TTS for `wo` / `ff`** — silent UI, leaves users for whom
///    TTS is *most* useful (those who can't read) without anything.
/// 2. **Use `fr` voice as fallback** — French is the administrative
///    language across Senegal, the recommendation strings already exist
///    in French in the agro-rules JSON, and most users have at least
///    auditory familiarity with French. Imperfect (pronunciation of
///    Wolof/Pulaar place names is wrong) but useful.
/// 3. **Server-side TTS with a Wolof voice (e.g. Coqui, ElevenLabs)** —
///    bandwidth-heavy, breaks offline-first contract.
///
/// We picked option 2. The fallback is documented in [speak] so the UI
/// can flag it (e.g. "lecture en français"). When/if a Wolof voice
/// becomes available we can lift the fallback.
class TtsService {
  TtsService() : _tts = FlutterTts();

  final FlutterTts _tts;
  bool _initialized = false;
  String _activeLanguageTag = 'fr-FR';

  /// One-shot init. Idempotent — safe to call before each [speak].
  Future<void> _ensureInit() async {
    if (_initialized) return;
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.55); // slightly faster than normal
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('TtsService init failed: $e');
    }
  }

  /// Resolve the BCP-47 language tag to use for [lang]. Falls back to
  /// French (`fr-FR`) when the platform engine has no voice for the
  /// requested code (Wolof / Pulaar are virtually never installed).
  ///
  /// Returns a record `(tag, isFallback)` so the caller can surface the
  /// fallback in the UI ("lecture en français" badge on the speak
  /// button) when relevant.
  Future<({String tag, bool isFallback})> _resolveLanguage(
    AppLanguage lang,
  ) async {
    final preferred = switch (lang) {
      AppLanguage.fr => 'fr-FR',
      AppLanguage.en => 'en-US',
      AppLanguage.wo => 'wo-SN',
      AppLanguage.ff => 'ff-SN',
    };

    try {
      final available = (await _tts.getLanguages) as List?;
      if (available == null) {
        return (tag: 'fr-FR', isFallback: lang != AppLanguage.fr);
      }
      final lower = available.map((e) => '$e'.toLowerCase()).toSet();
      if (lower.contains(preferred.toLowerCase())) {
        return (tag: preferred, isFallback: false);
      }
      // Try a same-language match without the region tag
      final base = preferred.split('-').first;
      final loose = lower.firstWhere(
        (l) => l.startsWith('$base-'),
        orElse: () => '',
      );
      if (loose.isNotEmpty) {
        return (tag: loose, isFallback: false);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('TtsService getLanguages failed: $e');
    }
    return (tag: 'fr-FR', isFallback: lang != AppLanguage.fr);
  }

  /// Speak [text] in the voice closest to [lang]. Stops any in-flight
  /// utterance first. Returns whether the platform fell back to French.
  Future<bool> speak(String text, {required AppLanguage lang}) async {
    await _ensureInit();
    await stop();
    final resolved = await _resolveLanguage(lang);
    if (resolved.tag != _activeLanguageTag) {
      try {
        await _tts.setLanguage(resolved.tag);
        _activeLanguageTag = resolved.tag;
      } catch (e) {
        if (kDebugMode) debugPrint('TtsService setLanguage failed: $e');
      }
    }
    try {
      await _tts.speak(text);
    } catch (e) {
      if (kDebugMode) debugPrint('TtsService speak failed: $e');
    }
    return resolved.isFallback;
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});
