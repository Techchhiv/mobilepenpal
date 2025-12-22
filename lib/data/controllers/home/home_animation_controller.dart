import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeBubble {
  double x; // 0..1
  double y; // 0..1
  double r; // px
  double phase; // 0..1 (offset so each bubble is at different time)
  double prevU; // track wrap per bubble

  HomeBubble({
    required this.x,
    required this.y,
    required this.r,
    required this.phase,
    this.prevU = 0,
  });
}

class HomeAnimationController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController bubbleController;

  final _rand = Random();

  final int bubbleCount = 12;
  final double minRadius = 3.0;
  final double maxRadius = 9.0;

  final double floatUp = 8.0;

  late List<HomeBubble> bubbles;

  double get t => bubbleController.value; 

  @override
  void onInit() {
    super.onInit();

    bubbles = List.generate(bubbleCount, (_) => _newBubble());

    bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..addListener(_tick);

    bubbleController.repeat();
  }

  HomeBubble _newBubble() {
    double rx() => 0.06 + _rand.nextDouble() * 0.88;
    double ry() => 0.10 + _rand.nextDouble() * 0.80;
    double rr() => minRadius + _rand.nextDouble() * (maxRadius - minRadius);
    double rp() => _rand.nextDouble();

    return HomeBubble(
      x: rx(),
      y: ry(),
      r: rr(),
      phase: rp(),
      prevU: 0,
    );
  }

  void _tick() {
    for (final b in bubbles) {
      final u = ((t + b.phase) % 1.0);

      if (u < b.prevU) {
        final nb = _newBubble();
        b.x = nb.x;
        b.y = nb.y;
        b.r = nb.r;
        b.phase = nb.phase;
        b.prevU = 0;
      } else {
        b.prevU = u;
      }
    }
  }

  double bubbleU(HomeBubble b) => ((t + b.phase) % 1.0);

  double bubbleAlphaFromU(double u) {
    final s = sin(pi * u);
    final a = s * s;

    return 0.06 + a * 0.28;
  }

  double bubbleYOffsetFromU(double u) {
    return -floatUp * u;
  }

  @override
  void onClose() {
    bubbleController.dispose();
    super.onClose();
  }
}
