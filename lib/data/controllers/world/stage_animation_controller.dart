import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum DrawFeedback { none, correct, wrong }

class StageAnimationController extends GetxController
    with GetTickerProviderStateMixin {
  final feedback = DrawFeedback.none.obs;
  final shakeOffset = 0.0.obs;
  final praiseText = ''.obs;
  final drawScale = 0.65.obs;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  late final ConfettiController confettiController;

  late final AnimationController guideController;
  final currentGuideStrokeIndex = 0.obs;
  final guideCirclePx = Rxn<Offset>();
  final isGuiding = true.obs;

  final guideDurationMs = 2000.obs;

  double _boardW = 340;
  double _boardH = 340;

  double _boundsW = 1;
  double _boundsH = 1;

  final guideStrokesPx = <List<Offset>>[].obs;

  @override
  void onInit() {
    super.onInit();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 12,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);

    _shakeAnimation.addListener(() {
      shakeOffset.value = _shakeAnimation.value;
    });

    confettiController = ConfettiController(
      duration: const Duration(milliseconds: 800),
    );

    guideController =
        AnimationController(
            vsync: this,
            duration: Duration(milliseconds: guideDurationMs.value),
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

  void setGuideFromNormalized({
    required List<List<Offset>> strokesNorm,
    required double boundsW,
    required double boundsH,
  }) {
    _boundsW = boundsW;
    _boundsH = boundsH;
    if (strokesNorm.isEmpty) {
      guideStrokesPx.clear();
      guideCirclePx.value = null;
      currentGuideStrokeIndex.value = 0;
      stopGuide();
      return;
    }

    final px = <List<Offset>>[];
    for (final stroke in strokesNorm) {
      if (stroke.isEmpty) continue;
      px.add(stroke.map(normToBoardPx).toList());
    }

    if (px.isEmpty) {
      guideStrokesPx.clear();
      guideCirclePx.value = null;
      currentGuideStrokeIndex.value = 0;
      stopGuide();
      return;
    }

    guideStrokesPx.assignAll(px);

    currentGuideStrokeIndex.value = 0;
    guideCirclePx.value = px.first.first;

    startGuide();
  }

  Offset normToBoardPx(Offset n) {
    final w = _boundsW;
    final h = _boundsH;

    if (w <= 0 || h <= 0) {
      final s = min(_boardW, _boardH) * drawScale.value;
      final ox = (_boardW - s) / 2;
      final oy = (_boardH - s) / 2;
      return Offset(ox + n.dx * s, oy + n.dy * s);
    }

    final boardAspect = _boardW / _boardH;
    final shapeAspect = w / h;

    double drawW, drawH;

    if (shapeAspect > boardAspect) {
      drawW = _boardW * drawScale.value;
      drawH = drawW / shapeAspect;
    } else {
      drawH = _boardH * drawScale.value;
      drawW = drawH * shapeAspect;
    }

    final ox = (_boardW - drawW) / 2;
    final oy = (_boardH - drawH) / 2;

    return Offset(ox + n.dx * drawW, oy + n.dy * drawH);
  }

  void startGuide() {
    if (guideStrokesPx.isEmpty) return;

    isGuiding.value = true;
    guideController.duration = Duration(milliseconds: _perStrokeDurationMs());

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

    guideController.duration = Duration(milliseconds: _perStrokeDurationMs());
  }

  void _updateGuideCircle() {
    if (!isGuiding.value) return;

    final idx = currentGuideStrokeIndex.value;
    if (idx < 0 || idx >= guideStrokesPx.length) return;

    final stroke = guideStrokesPx[idx];
    if (stroke.length < 2) return;

    guideCirclePx.value = _pointAtByDistance(stroke, guideController.value);
  }

  double _polyLen(List<Offset> pts) {
    double len = 0;
    for (int i = 1; i < pts.length; i++) {
      len += (pts[i] - pts[i - 1]).distance;
    }
    return len;
  }

  Offset _pointAtByDistance(List<Offset> pts, double t) {
    if (pts.isEmpty) return Offset.zero;
    if (pts.length == 1) return pts.first;

    final total = _polyLen(pts);
    if (total <= 0) return pts.first;

    final target = total * t;
    double acc = 0;

    for (int i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final seg = (b - a).distance;
      if (seg <= 0) continue;

      if (acc + seg >= target) {
        final localT = (target - acc) / seg;
        return Offset(
          a.dx + (b.dx - a.dx) * localT,
          a.dy + (b.dy - a.dy) * localT,
        );
      }
      acc += seg;
    }
    return pts.last;
  }

  int _perStrokeDurationMs() {
    final n = guideStrokesPx.length;
    if (n <= 0) return guideDurationMs.value;

    final weightedTotal = guideDurationMs.value * pow(1.2, n - 1);

    final perStroke = weightedTotal / n;

    return perStroke.round();
  }
}
