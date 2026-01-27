import 'package:flutter/animation.dart';
import 'package:get/get.dart';

class WorldAnimationController extends GetxController
    with GetTickerProviderStateMixin {
  int waveDurationMs = 1600; // smaller = faster wave
  int bounceDurationMs = 650; // smaller = faster bounce
  double bounceHeight = 8.0; // how high it bounces

  double waveAmplitudeFactor = 0.06; // relative to circle height
  double waveAmplitudeMin = 2.0; // minimum amplitude
  double waveWavelengthFactor = 0.95; // relative to circle width

  late final AnimationController waveCtrl;
  late final AnimationController bounceCtrl;

  bool _active = false;

  @override
  void onInit() {
    super.onInit();

    waveCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: waveDurationMs),
    );

    bounceCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: bounceDurationMs),
    );
  }

  void setActive(bool active) {
    if (_active == active) return;
    _active = active;

    if (active) {
      if (!waveCtrl.isAnimating) waveCtrl.repeat();
      if (!bounceCtrl.isAnimating) bounceCtrl.repeat(reverse: true);
    } else {
      if (waveCtrl.isAnimating) waveCtrl.stop();
      if (bounceCtrl.isAnimating) bounceCtrl.stop();
      waveCtrl.value = 0;
      bounceCtrl.value = 0;
    }
  }

  @override
  void onClose() {
    waveCtrl.dispose();
    bounceCtrl.dispose();
    super.onClose();
  }
}
