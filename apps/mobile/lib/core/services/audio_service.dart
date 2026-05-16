import 'dart:async';
import 'dart:io';

import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

enum AudioState { idle, recording, playing }

class AudioNote {
  final String path;
  final Duration duration;
  const AudioNote({required this.path, required this.duration});
}

/// Service audio gérant l'enregistrement et la lecture.
/// Utilise le package 'record' pour l'acquisition.
class AudioService {
  AudioService() : _record = AudioRecorder();

  final AudioRecorder _record;
  Timer? _timer;
  DateTime? _startTime;
  bool _isRecording = false;

  /// Vérifie et demande les permissions micro.
  Future<bool> hasPermission() async {
    return await _record.hasPermission();
  }

  Future<String?> _outputPath() async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${dir.path}/audio_notes');
      if (!await audioDir.exists()) await audioDir.create(recursive: true);
      final ts = DateTime.now().millisecondsSinceEpoch;
      return '${audioDir.path}/note_$ts.m4a';
    } catch (_) {
      return null;
    }
  }

  /// Démarre l'enregistrement audio.
  Future<String?> startRecording() async {
    if (await _record.hasPermission()) {
      final path = await _outputPath();
      if (path == null) return null;

      const config = RecordConfig(); // Default configuration (m4a/aac)

      await _record.start(config, path: path);
      _startTime = DateTime.now();
      _isRecording = true;
      return path;
    }
    return null;
  }

  /// Arrête l'enregistrement et retourne la note audio.
  Future<AudioNote?> stopRecording() async {
    final path = await _record.stop();
    _isRecording = false;
    if (path == null || _startTime == null) return null;

    final duration = DateTime.now().difference(_startTime!);
    _startTime = null;
    return AudioNote(path: path, duration: duration);
  }

  bool get isRecording => _isRecording;

  Duration get elapsed => _startTime != null
      ? DateTime.now().difference(_startTime!)
      : Duration.zero;

  Future<void> dispose() async {
    _timer?.cancel();
    await _record.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((_) => AudioService());

/// Controller wrapping a single [AudioPlayer] for UI playback.
class AudioPlaybackController {
  AudioPlaybackController() {
    _player.onPlayerStateChanged.listen((s) {
      _isPlaying = s == PlayerState.playing;
      _stateCtrl.add(_isPlaying);
    });
    _player.onPositionChanged.listen((p) {
      _positionCtrl.add(p);
    });
    _player.onPlayerComplete.listen((_) {
      _stateCtrl.add(false);
    });
  }
  final _player = AudioPlayer();
  final _stateCtrl = StreamController<bool>.broadcast();
  final _positionCtrl = StreamController<Duration>.broadcast();
  bool _isPlaying = false;
  String? _currentPath;

  Stream<bool> get onStateChanged => _stateCtrl.stream;
  Stream<Duration> get positionStream => _positionCtrl.stream;
  Stream<Duration> get durationStream => _player.onDurationChanged;
  Stream<PlayerState> get stateStream => _player.onPlayerStateChanged;

  bool get isPlaying => _isPlaying;
  Duration get position => Duration.zero;
  String? get currentPath => _currentPath;
  AudioPlayer get player => _player;

  Future<void> play(String path, {Duration? fallbackDuration}) async {
    _currentPath = path;
    await _player.play(DeviceFileSource(path));
  }

  void pause() => _player.pause();
  Future<void> resume() => _player.resume();
  void stop() => _player.stop();
  void seek(Duration pos) => _player.seek(pos);

  Future<void> dispose() async {
    await _player.dispose();
    await _stateCtrl.close();
    await _positionCtrl.close();
  }
}

final audioPlaybackProvider = Provider<AudioPlaybackController>(
  (_) => AudioPlaybackController(),
);
