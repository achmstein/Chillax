import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays short sound effects for success actions (order placed, room reserved).
class SoundService {
  static final SoundService _instance = SoundService._();
  static SoundService get instance => _instance;

  final _player = AudioPlayer();

  SoundService._();

  /// Play the success sound effect.
  Future<void> playSuccess() async {
    try {
      await _player.setVolume(0.15);
      await _player.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      debugPrint('Failed to play sound: $e');
    }
  }
}
