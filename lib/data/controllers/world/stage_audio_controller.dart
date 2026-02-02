import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

class StageAudioController extends GetxController {
  final AudioPlayer _voicePlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer(playerId: 'sfx');

  final audioSpeed = 0.5.obs;
  final isPlaying = false.obs;

  String sfxPath(String name) => 'audios/sfx/$name.mp3';
  bool _busy = false;
  int _token = 0;
  DateTime? _lastAutoPlayAt;

  @override
  void onInit() {
    super.onInit();

    _voicePlayer.setReleaseMode(ReleaseMode.stop);
    _sfxPlayer.setReleaseMode(ReleaseMode.stop);

    // _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);

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

    final token = ++_token;
    if (_busy) return;
    _busy = true;

    try {
      await _voicePlayer.stop();

      try {
        await _voicePlayer.setPlaybackRate(audioSpeed.value);
      } catch (_) {}

      if (token != _token) return;

      await _voicePlayer.play(AssetSource(relPath), position: Duration.zero);
    } finally {
      _busy = false;
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

  Future<void> playSfx(String name) async {
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource(sfxPath(name)), position: Duration.zero);
  }

  Future<void> playCorrectSfx() => playSfx('correct');
  Future<void> playWrongSfx() => playSfx('incorrect');

  Future<void> stopVoice() => _voicePlayer.stop();
  Future<void> stopAll() async {
    await _voicePlayer.stop();
    await _sfxPlayer.stop();
  }
}
