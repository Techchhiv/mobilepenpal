import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WorldAnimationController extends GetxController
    with GetTickerProviderStateMixin {
  int waveDurationMs = 1600;
  int bounceDurationMs = 650;

  double bounceHeight = 8.0;

  double waveAmplitudeFactor = 0.06;
  double waveAmplitudeMin = 2.0;
  double waveWavelengthFactor = 0.95;

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
    _waveActive = active;

    if (active) {
      waveCtrl.repeat();
    } else {
      waveCtrl.stop();
      waveCtrl.value = 0;
    }
  }

  void setBounceActive(bool active) {
    _bounceActive = active;

    if (active) {
      bounceCtrl.repeat(reverse: true);
    } else {
      bounceCtrl.stop();
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
