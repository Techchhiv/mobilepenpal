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

  bool _waveActive = false;
  bool _bounceActive = false;

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

  void setWaveActive(bool active) {
    if (_waveActive == active) return;
    _waveActive = active;

    if (active) {
      if (!waveCtrl.isAnimating) {
        waveCtrl.repeat();
      }
    } else {
      if (waveCtrl.isAnimating) {
        waveCtrl.stop();
      }
      waveCtrl.value = 0;
    }
  }

  void setBounceActive(bool active) {
    if (_bounceActive == active) return;
    _bounceActive = active;

    if (active) {
      if (!bounceCtrl.isAnimating) {
        bounceCtrl.repeat(reverse: true);
      }
    } else {
      if (bounceCtrl.isAnimating) {
        bounceCtrl.stop();
      }
      bounceCtrl.value = 0;
    }
  }

  void setActive(bool active) {
    setWaveActive(active);
    setBounceActive(active);
  }

  @override
  void onClose() {
    waveCtrl.dispose();
    bounceCtrl.dispose();
    super.onClose();
  }
}
