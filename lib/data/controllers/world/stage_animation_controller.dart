import 'dart:convert';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

enum DrawFeedback { none, correct, wrong }

class StageAnimationController extends GetxController
    with GetTickerProviderStateMixin {
  final feedback = DrawFeedback.none.obs;
  final shakeOffset = 0.0.obs;
  final praiseText = ''.obs;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  late final ConfettiController confettiController;

  late final AnimationController guideController;
  final currentGuideStrokeIndex = 0.obs;
  final guideCirclePx = Rxn<Offset>();
  final isGuiding = true.obs;

  double _boardW = 340;
  double _boardH = 340;

  final guideStrokesPx = <List<Offset>>[].obs;

  final List<List<double>> _cumLenByStroke = [];
  final List<double> _totalLenByStroke = [];

  final guideSpeedPxPerSec = 250.0.obs;

  final minStrokeDurationMs = 450.obs;
  final maxStrokeDurationMs = 2600.obs;

  final _rng = Random();
  List<String>? _digitFruitAssets;
  final Map<int, String> _fruitByDigit = {};
  Set<String>? _assetKeysCache;

  final illustrationAssetPath = ''.obs;
  final illustrationLabel = ''.obs;

  @override
  void onInit() {
    super.onInit();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _shakeAnimation =
        Tween<double>(
            begin: 0,
            end: 12,
          ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController)
          ..addListener(() {
            shakeOffset.value = _shakeAnimation.value;
          });

    confettiController = ConfettiController(
      duration: const Duration(milliseconds: 800),
    );

    guideController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1000),
          )
          ..addListener(_updateGuideCircle)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _advanceGuideStroke();
              if (isGuiding.value) guideController.forward(from: 0);
            }
          });
  }

  @override
  void onClose() {
    _shakeController.dispose();
    confettiController.dispose();
    guideController.dispose();
    super.onClose();
  }

  void setBoardSize({required double width, required double height}) {
    _boardW = width;
    _boardH = height;
  }

  void setGuideFromPx({required List<List<Offset>> strokesPx}) {
    final cleaned = strokesPx.where((s) => s.length >= 2).toList();

    if (cleaned.isEmpty) {
      guideStrokesPx.clear();
      guideCirclePx.value = null;
      currentGuideStrokeIndex.value = 0;
      stopGuide();

      _cumLenByStroke.clear();
      _totalLenByStroke.clear();
      return;
    }

    guideStrokesPx.assignAll(cleaned);

    _cumLenByStroke
      ..clear()
      ..addAll(cleaned.map(_buildCumLen));
    _totalLenByStroke
      ..clear()
      ..addAll(_cumLenByStroke.map((c) => c.isEmpty ? 0.0 : c.last));

    currentGuideStrokeIndex.value = 0;
    guideCirclePx.value = cleaned.first.first;

    startGuide();
  }

  List<double> _buildCumLen(List<Offset> stroke) {
    final n = stroke.length;
    if (n == 0) return const [];
    final cum = List<double>.filled(n, 0.0);
    double acc = 0.0;
    for (int i = 1; i < n; i++) {
      acc += (stroke[i] - stroke[i - 1]).distance;
      cum[i] = acc;
    }
    return cum;
  }

  void startGuide() {
    if (guideStrokesPx.isEmpty) return;

    isGuiding.value = true;
    guideController.duration = Duration(
      milliseconds: _durationForStrokeMs(currentGuideStrokeIndex.value),
    );
    guideController.forward(from: 0);
  }

  void stopGuide() {
    isGuiding.value = false;
    guideController.stop();
  }

  void showCorrect() {
    feedback.value = DrawFeedback.correct;
    praiseText.value = ['ល្អណាស់!', 'ធ្វើបានល្អ 👍'][Random().nextInt(2)];
    confettiController.play();
  }

  Future<void> showWrongAndReset({required VoidCallback onAfterReset}) async {
    feedback.value = DrawFeedback.wrong;
    praiseText.value = '';
    _shakeController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 400));
    feedback.value = DrawFeedback.none;

    await Future.delayed(const Duration(milliseconds: 300));
    onAfterReset();
  }

  void clearPraise() => praiseText.value = '';

  void _advanceGuideStroke() {
    if (guideStrokesPx.isEmpty) return;

    final next = currentGuideStrokeIndex.value + 1;
    currentGuideStrokeIndex.value = (next >= guideStrokesPx.length) ? 0 : next;

    final stroke = guideStrokesPx[currentGuideStrokeIndex.value];
    guideCirclePx.value = stroke.isNotEmpty ? stroke.first : null;

    guideController.duration = Duration(
      milliseconds: _durationForStrokeMs(currentGuideStrokeIndex.value),
    );
  }

  void _updateGuideCircle() {
    if (!isGuiding.value) return;

    final idx = currentGuideStrokeIndex.value;
    if (idx < 0 || idx >= guideStrokesPx.length) return;

    final stroke = guideStrokesPx[idx];
    if (stroke.length < 2) return;

    final cum = _cumLenByStroke[idx];
    final total = _totalLenByStroke[idx];
    if (cum.length != stroke.length || total <= 0) {
      guideCirclePx.value = stroke.first;
      return;
    }

    guideCirclePx.value = _pointAtByCumLen(
      stroke,
      cum,
      total,
      guideController.value,
    );
  }

  Offset _pointAtByCumLen(
    List<Offset> pts,
    List<double> cum,
    double total,
    double t,
  ) {
    final target = total * t.clamp(0.0, 1.0);

    int lo = 0, hi = cum.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (cum[mid] >= target) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }

    final i = lo;
    if (i <= 0) return pts.first;

    final prevLen = cum[i - 1];
    final segLen = cum[i] - prevLen;
    if (segLen <= 0) return pts[i];

    final localT = (target - prevLen) / segLen;
    final a = pts[i - 1];
    final b = pts[i];
    return Offset(a.dx + (b.dx - a.dx) * localT, a.dy + (b.dy - a.dy) * localT);
  }

  int _durationForStrokeMs(int strokeIndex) {
    if (strokeIndex < 0 || strokeIndex >= _totalLenByStroke.length) {
      return minStrokeDurationMs.value;
    }

    final lenPx = _totalLenByStroke[strokeIndex];
    final speed = max(10.0, guideSpeedPxPerSec.value);

    final rawMs = (lenPx / speed * 1000.0).round();

    return rawMs.clamp(minStrokeDurationMs.value, maxStrokeDurationMs.value);
  }

  Future<void> _ensureAssetManifestLoaded() async {
    if (_assetKeysCache != null) return;

    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _assetKeysCache = manifest.listAssets().toSet();
    } catch (e) {
      _assetKeysCache = <String>{};
    }
  }

  Future<void> resolveIllustration({
    required String characterType,
    required String character,
  }) async {
    final type = characterType.trim().toLowerCase();
    final ch = character.trim();

    if (type.isEmpty || ch.isEmpty) {
      illustrationAssetPath.value = '';
      illustrationLabel.value = '';
      return;
    }

    if (type == 'digits') {
      await _resolveDigitFruit(ch);
      return;
    }
    await _ensureAssetManifestLoaded();
    final keys = _assetKeysCache ?? const <String>{};

    final prefix = 'assets/images/$type/${ch}_';

    final matches = keys
        .where((k) => k.startsWith(prefix) && k.toLowerCase().endsWith('.png'))
        .toList();

    if (matches.isEmpty) {
      illustrationAssetPath.value = '';
      illustrationLabel.value = '';
      return;
    }

    matches.sort();
    final picked = matches.first;

    illustrationAssetPath.value = picked;

    final file = picked.split('/').last;
    final underscore = file.indexOf('_');
    final dot = file.lastIndexOf('.');
    if (underscore != -1 && dot != -1 && dot > underscore) {
      illustrationLabel.value = file.substring(underscore + 1, dot);
    } else {
      illustrationLabel.value = '';
    }
  }

  Future<List<String>> _loadDigitFruitAssets() async {
    if (_digitFruitAssets != null) return _digitFruitAssets!;

    await _ensureAssetManifestLoaded();
    final keys = _assetKeysCache ?? const <String>{};

    const prefix = 'assets/images/digits/';
    final matches = keys
        .where((k) => k.startsWith(prefix) && k.toLowerCase().endsWith('.png'))
        .toList();

    matches.sort();
    _digitFruitAssets = matches;
    return matches;
  }

  Future<void> _resolveDigitFruit(String digitChar) async {
    final d = _parseDigitAny(digitChar);
    if (d == null) {
      illustrationAssetPath.value = '';
      illustrationLabel.value = '';
      return;
    }

    final fruits = await _loadDigitFruitAssets();
    if (fruits.isEmpty) {
      // nothing found in AssetManifest
      illustrationAssetPath.value = '';
      illustrationLabel.value = digitChar.trim();
      return;
    }

    final picked = _fruitByDigit.putIfAbsent(
      d,
      () => fruits[_rng.nextInt(fruits.length)],
    );

    illustrationAssetPath.value = picked;
    illustrationLabel.value = digitChar.trim();
  }

  int? _parseDigitAny(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    final ascii = int.tryParse(s);
    if (ascii != null) return ascii;

    const kh = {
      '០': 0,
      '១': 1,
      '២': 2,
      '៣': 3,
      '៤': 4,
      '៥': 5,
      '៦': 6,
      '៧': 7,
      '៨': 8,
      '៩': 9,
    };

    if (s.length == 1 && kh.containsKey(s)) return kh[s];

    int acc = 0;
    bool ok = false;
    for (final ch in s.characters) {
      final v = kh[ch];
      if (v == null) return null;
      ok = true;
      acc = acc * 10 + v;
    }
    return ok ? acc : null;
  }
}
