import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';

class StageAudioController extends GetxController {
  final AudioPlayer _voicePlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  final audioSpeed = 0.5.obs;
  final isPlaying = false.obs;

  int _voiceToken = 0;
  DateTime? _lastAutoPlayAt;

  Future<void> _sfxQueue = Future.value();

  @override
  void onInit() {
    super.onInit();

    _voicePlayer.setReleaseMode(ReleaseMode.stop);
    _sfxPlayer.setReleaseMode(ReleaseMode.stop);

    _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);

    _voicePlayer.onPlayerStateChanged.listen((state) {
      isPlaying.value = state == PlayerState.playing;
    });
  }

  @override
  void onClose() {
    _voicePlayer.dispose();
    _sfxPlayer.dispose();
    super.onClose();
  }

  String assetPathForCharacter({required String type, required String ch}) {
    final t = type.trim().toLowerCase();
    final c = ch.trim();
    return 'audios/$t/$c.mp3';
  }

  Future<void> playVoiceAsset(String relPath) async {
    if (relPath.trim().isEmpty) return;

    final token = ++_voiceToken;

    try {
      await _voicePlayer.stop();

      try {
        await _voicePlayer.setPlaybackRate(audioSpeed.value);
      } catch (_) {}

      if (token != _voiceToken) return;

      String path = relPath;
      if (!path.startsWith('assets/')) {
        path = 'assets/$path';
      }

      final byteData = await rootBundle.load(path);
      if (token != _voiceToken) return;

      final bytes = byteData.buffer.asUint8List();
      if (token != _voiceToken) return;

      await _voicePlayer.play(BytesSource(bytes));
    } catch (e) {
      debugPrint('[StageAudio] Failed to play voice "$relPath": $e');
    }
  }

  Future<void> playCharacter({required String type, required String ch}) async {
    final rel = assetPathForCharacter(type: type, ch: ch);
    await playVoiceAsset(rel);
  }

  Future<void> autoPlayCharacter({
    required String type,
    required String ch,
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

  Future<void> playSfx(String name) {
    _sfxQueue = _sfxQueue.catchError((_) {}).then((_) async {
      try {
        await _sfxPlayer.stop();
        await _sfxPlayer.play(AssetSource('audios/sfx/$name.mp3'));
      } catch (e) {
        debugPrint('[StageAudio] Failed to play SFX "$name": $e');
      }
    });

    return _sfxQueue;
  }

  Future<void> playCorrectSfx() => playSfx('correct');
  Future<void> playWrongSfx() => playSfx('incorrect');

  Future<void> stopVoice() async {
    try {
      await _voicePlayer.stop();
    } catch (_) {}
  }

  Future<void> stopAll() async {
    _voiceToken++;
    try {
      await _voicePlayer.stop();
    } catch (_) {}
    try {
      await _sfxPlayer.stop();
    } catch (_) {}
  }
}
