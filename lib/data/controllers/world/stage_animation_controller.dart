import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';

enum DrawFeedback { none, correct, wrong }

enum StarState { pending, correct, wrong }

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

  final guideTotalDurationMs = 4000.obs;
  final pauseBetweenStrokesMs = 180.obs;

  final List<int> _durationMsByStroke = [];
  final List<double> _lenByStroke = [];
  double _totalLenAll = 0.0;

  Timer? _betweenStrokeTimer;

  final animatingStarIndex = RxnInt();
  final completedStarCount = 0.obs;
  final starScale = 1.0.obs;

  double _boardW = 340;
  double _boardH = 340;

  final guideStrokesPx = <List<Offset>>[].obs;

  final List<List<double>> _cumLenByStroke = [];
  final List<double> _totalLenByStroke = [];

  final minStrokeDurationMs = 1500.obs;
  final maxStrokeDurationMs = 3000.obs;

  final _rng = Random();
  List<String>? _digitFruitAssets;
  final Map<int, String> _fruitByDigit = {};
  Set<String>? _assetKeysCache;

  final illustrationAssetPath = ''.obs;
  final illustrationLabel = ''.obs;

  final starStates = <StarState>[].obs;

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
            if (status != AnimationStatus.completed) return;

            _advanceGuideStroke();
            if (!isGuiding.value) return;

            _betweenStrokeTimer?.cancel();
            final pause = pauseBetweenStrokesMs.value;

            if (pause <= 0) {
              guideController.forward(from: 0);
              return;
            }

            _betweenStrokeTimer = Timer(Duration(milliseconds: pause), () {
              if (!isGuiding.value) return;
              guideController.forward(from: 0);
            });
          });
  }

  @override
  void onClose() {
    _betweenStrokeTimer?.cancel();
    _betweenStrokeTimer = null;

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
      _durationMsByStroke.clear();
      _lenByStroke.clear();
      _totalLenAll = 0.0;
      _betweenStrokeTimer?.cancel();
      _betweenStrokeTimer = null;
      return;
    }

    guideStrokesPx.assignAll(cleaned);

    _cumLenByStroke
      ..clear()
      ..addAll(cleaned.map(_buildCumLen));
    _totalLenByStroke
      ..clear()
      ..addAll(_cumLenByStroke.map((c) => c.isEmpty ? 0.0 : c.last));

    _lenByStroke
      ..clear()
      ..addAll(_totalLenByStroke);

    _totalLenAll = _lenByStroke.fold(0.0, (a, b) => a + b);

    _durationMsByStroke
      ..clear()
      ..addAll(_buildStrokeDurationsConstantTotal());

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

    _betweenStrokeTimer?.cancel();
    _betweenStrokeTimer = null;

    isGuiding.value = true;

    guideController.duration = Duration(
      milliseconds: _strokeDurationMs(currentGuideStrokeIndex.value),
    );

    guideController.forward(from: 0);
  }

  void stopGuide() {
    isGuiding.value = false;
    _betweenStrokeTimer?.cancel();
    _betweenStrokeTimer = null;
    guideController.stop();
  }

  void restartGuideFromStart() {
    if (guideStrokesPx.isEmpty) return;
    currentGuideStrokeIndex.value = 0;
    guideCirclePx.value = guideStrokesPx.first.isNotEmpty
        ? guideStrokesPx.first.first
        : null;
    startGuide();
  }

  void showCorrect({required int starIndex}) {
    feedback.value = DrawFeedback.correct;
    praiseText.value = [
      'praise_excellent'.tr,
      'praise_well_done'.tr,
    ][Random().nextInt(2)];
    confettiController.play();

    markCorrect(starIndex);
    playStarPop(starIndex);
  }

  Future<void> showWrongAndReset({required VoidCallback onAfterReset}) async {
    feedback.value = DrawFeedback.wrong;
    _shakeController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 1200));
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
      milliseconds: _strokeDurationMs(currentGuideStrokeIndex.value),
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
    final d = NumberFormatUtils.parseSingleDigitAny(digitChar);
    if (d == null) {
      illustrationAssetPath.value = '';
      illustrationLabel.value = '';
      return;
    }

    final fruits = await _loadDigitFruitAssets();
    if (fruits.isEmpty) {
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

  List<int> _buildStrokeDurationsConstantTotal() {
    final totalMs = guideTotalDurationMs.value;

    if (_lenByStroke.isEmpty || _totalLenAll <= 0) {
      return <int>[
        totalMs.clamp(minStrokeDurationMs.value, maxStrokeDurationMs.value),
      ];
    }

    final out = <int>[];
    int assigned = 0;

    for (int i = 0; i < _lenByStroke.length; i++) {
      final share = _lenByStroke[i] / _totalLenAll;
      int ms = (totalMs * share).round();

      ms = ms.clamp(minStrokeDurationMs.value, maxStrokeDurationMs.value);

      out.add(ms);
      assigned += ms;
    }

    if (out.isNotEmpty) {
      final fix = totalMs - assigned;
      out[out.length - 1] = (out.last + fix).clamp(
        minStrokeDurationMs.value,
        maxStrokeDurationMs.value,
      );
    }

    return out;
  }

  int _strokeDurationMs(int idx) {
    if (idx < 0 || idx >= _durationMsByStroke.length) {
      return minStrokeDurationMs.value;
    }
    return _durationMsByStroke[idx];
  }

  void resetStars({int? total}) {
    if (total != null) {
      starStates.assignAll(List.filled(total, StarState.pending));
    } else {
      if (starStates.isNotEmpty) {
        for (int i = 0; i < starStates.length; i++) {
          starStates[i] = StarState.pending;
        }
        starStates.refresh();
      }
    }

    completedStarCount.value = 0;
    animatingStarIndex.value = null;
    starScale.value = 1.0;
  }

  Future<void> playStarPop(int index) async {
    animatingStarIndex.value = index;

    starScale.value = 2.5;
    await Future.delayed(const Duration(milliseconds: 380));

    starScale.value = 1.0;
    await Future.delayed(const Duration(milliseconds: 400));

    animatingStarIndex.value = null;
  }

  void markCorrect(int index) {
    if (index < 0) return;
    if (index >= starStates.length) return;

    starStates[index] = StarState.correct;
    starStates.refresh();

    completedStarCount.value = starStates
        .where((s) => s == StarState.correct)
        .length;
  }

  void markWrong(int index) {
    if (index < 0) return;
    if (index >= starStates.length) return;

    starStates[index] = StarState.wrong;
    starStates.refresh();
  }
}
