import 'dart:async';
import 'dart:io';

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

/// Simplified audio service.
/// Recording features disabled due to record package build issues on Linux.
/// Playback still works.
class AudioService {
  Timer? _timer;
  DateTime? _startTime;
  bool _isRecording = false;

  /// Recording temporarily disabled.
  Future<bool> hasPermission() async => false;

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

  /// Recording disabled - returns null.
  Future<String?> startRecording() async {
    // Recording temporarily disabled due to record package build issues
    return null;
  }

  /// Recording disabled - returns null.
  Future<AudioNote?> stopRecording() async {
    return null;
  }

  Duration get elapsed => _startTime != null
      ? DateTime.now().difference(_startTime!)
      : Duration.zero;

  Future<void> dispose() async {
    _timer?.cancel();
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
  Duration _duration = Duration.zero;

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
    if (fallbackDuration != null) {
      _duration = fallbackDuration;
    }
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
