import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class StageAudioController extends GetxController {
  final AudioPlayer _player = AudioPlayer();

  final audioSpeed = 0.5.obs;

  final isPlaying = false.obs;

  bool _busy = false;
  int _token = 0;

  DateTime? _lastAutoPlayAt;

  @override
  void onInit() {
    super.onInit();

    _player.setReleaseMode(ReleaseMode.stop);

    _player.onPlayerStateChanged.listen((state) {
      isPlaying.value = state == PlayerState.playing;
    });
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }

  String assetPathForCharacter({required String type, required String ch}) {
    final t = type.trim();
    final c = ch.trim();
    return 'audios/$t/$c.mp3';
  }

  Future<void> playAsset(String relPath) async {
    if (relPath.trim().isEmpty) return;

    final token = ++_token;
    if (_busy) return;
    _busy = true;

    try {
      await _player.stop();

      try {
        await _player.setPlaybackRate(audioSpeed.value);
      } catch (_) {}

      if (token != _token) return;

      await _player.play(
        AssetSource(relPath),
        position: Duration.zero,
      );
    } catch (e) {
      // debugPrint('Audio play failed: assets/$relPath  ($e)');
    } finally {
      _busy = false;
    }
  }

  Future<void> playCharacter({
    required String type,
    required String ch,
  }) async {
    final rel = assetPathForCharacter(type: type, ch: ch);
    await playAsset(rel);
  }
  
  Future<void> autoPlayCharacter({
    required String type,
    required String ch,
    Duration tapCooldown = const Duration(milliseconds: 400),
  }) async {
    _lastAutoPlayAt = DateTime.now();
    await playCharacter(type: type, ch: ch);
  }

  Future<void> playCharacterGuarded({
    required String type,
    required String ch,
    Duration cooldown = const Duration(milliseconds: 400),
  }) async {
    final last = _lastAutoPlayAt;
    if (last != null && DateTime.now().difference(last) < cooldown) return;
    await playCharacter(type: type, ch: ch);
  }

  Future<void> stop() => _player.stop();
}
