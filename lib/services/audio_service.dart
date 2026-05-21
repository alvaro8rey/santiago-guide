import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

enum AudioState { playing, paused, stopped }

class AudioService {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() {
    return _instance;
  }

  late final AudioPlayer _audioPlayer;
  late final StreamController<AudioState> _stateController;
  late final StreamController<Duration> _positionController;
  late final StreamController<Duration> _durationController;

  AudioService._internal() {
    _audioPlayer = AudioPlayer();
    _stateController = StreamController<AudioState>.broadcast();
    _positionController = StreamController<Duration>.broadcast();
    _durationController = StreamController<Duration>.broadcast();
    _setupListeners();
  }

  Stream<AudioState> get stateStream => _stateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;

  void _setupListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        _stateController.add(AudioState.playing);
      } else if (state == PlayerState.paused) {
        _stateController.add(AudioState.paused);
      } else {
        _stateController.add(AudioState.stopped);
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      _durationController.add(duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      _positionController.add(position);
    });
  }

  Future<void> play(String url) async {
    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _stateController.close();
    _positionController.close();
    _durationController.close();
  }
}
