import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

class HeartController extends GetxController with WidgetsBindingObserver {
  static HeartController get to => Get.find<HeartController>();

  static const int maxHearts = 5;
  static const int regenIntervalSeconds = 15 * 60; // 15 minutes = 900 seconds

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  var currentHearts = maxHearts.obs;
  var isUnlimited = false.obs;
  var secondsToNextHeart = 0.obs;
  var timeToNextHeartStr = ''.obs;

  int? _studentId;
  DateTime? _lastRegenTime;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndRegenerate();
    }
  }

  /// Initialize HeartController for a given student profile.
  Future<void> initForStudent({
    int? studentId,
    bool hasSubscription = false,
  }) async {
    _studentId = studentId;
    isUnlimited.value = hasSubscription;

    if (isUnlimited.value) {
      currentHearts.value = maxHearts;
      secondsToNextHeart.value = 0;
      timeToNextHeartStr.value = '';
      _timer?.cancel();
      return;
    }

    await _loadFromStorage();
    _checkAndRegenerate();
    _startTimer();
  }

  /// Load hearts and last regen timestamp from Keychain storage.
  Future<void> _loadFromStorage() async {
    if (_studentId == null) {
      currentHearts.value = maxHearts;
      _lastRegenTime = DateTime.now();
      return;
    }

    try {
      final savedHeartsStr = await _secure.read(
        key: 'student_${_studentId}_hearts',
      );
      final savedTimeStr = await _secure.read(
        key: 'student_${_studentId}_last_regen',
      );

      int loadedHearts = savedHeartsStr != null
          ? (int.tryParse(savedHeartsStr) ?? maxHearts)
          : maxHearts;

      DateTime loadedTime;
      if (savedTimeStr != null) {
        final millis = int.tryParse(savedTimeStr);
        loadedTime = millis != null
            ? DateTime.fromMillisecondsSinceEpoch(millis)
            : DateTime.now();
      } else {
        loadedTime = DateTime.now();
      }

      // Calculate elapsed time recovery BEFORE assigning to observable
      if (loadedHearts < maxHearts) {
        final now = DateTime.now();
        final elapsedSeconds = now.difference(loadedTime).inSeconds;
        if (elapsedSeconds > 0) {
          final recovered = elapsedSeconds ~/ regenIntervalSeconds;
          if (recovered > 0) {
            loadedHearts = (loadedHearts + recovered).clamp(0, maxHearts);
            if (loadedHearts >= maxHearts) {
              loadedTime = now;
            } else {
              loadedTime = loadedTime.add(
                Duration(seconds: recovered * regenIntervalSeconds),
              );
            }
          }
        }
      }

      _lastRegenTime = loadedTime;
      currentHearts.value = loadedHearts;
      await _saveToStorage();
    } catch (_) {
      currentHearts.value = maxHearts;
      _lastRegenTime = DateTime.now();
    }
  }

  /// Persist current heart state and last regen timestamp to Keychain.
  Future<void> _saveToStorage() async {
    if (_studentId == null) return;
    try {
      await _secure.write(
        key: 'student_${_studentId}_hearts',
        value: currentHearts.value.toString(),
      );
      if (_lastRegenTime != null) {
        await _secure.write(
          key: 'student_${_studentId}_last_regen',
          value: _lastRegenTime!.millisecondsSinceEpoch.toString(),
        );
      }
    } catch (_) {}
  }

  /// Calculate heart recovery based on elapsed time.
  void _checkAndRegenerate() {
    if (isUnlimited.value) return;

    if (currentHearts.value >= maxHearts) {
      secondsToNextHeart.value = 0;
      timeToNextHeartStr.value = '';
      return;
    }

    final now = DateTime.now();
    if (_lastRegenTime == null) {
      _lastRegenTime = now;
      _saveToStorage();
      return;
    }

    final elapsedSeconds = now.difference(_lastRegenTime!).inSeconds;
    if (elapsedSeconds < 0) return;

    final recoveredHearts = elapsedSeconds ~/ regenIntervalSeconds;
    if (recoveredHearts > 0) {
      currentHearts.value = (currentHearts.value + recoveredHearts).clamp(
        0,
        maxHearts,
      );

      if (currentHearts.value >= maxHearts) {
        _lastRegenTime = now;
        secondsToNextHeart.value = 0;
        timeToNextHeartStr.value = '';
      } else {
        _lastRegenTime = _lastRegenTime!.add(
          Duration(seconds: recoveredHearts * regenIntervalSeconds),
        );
        final remaining =
            regenIntervalSeconds - (now.difference(_lastRegenTime!).inSeconds);
        secondsToNextHeart.value = remaining.clamp(0, regenIntervalSeconds);
        timeToNextHeartStr.value = _formatDuration(secondsToNextHeart.value);
      }
      _saveToStorage();
    } else {
      final remaining = regenIntervalSeconds - elapsedSeconds;
      secondsToNextHeart.value = remaining.clamp(0, regenIntervalSeconds);
      timeToNextHeartStr.value = _formatDuration(secondsToNextHeart.value);
    }
  }

  /// Periodic timer tick to update countdown and regenerate hearts.
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isUnlimited.value || currentHearts.value >= maxHearts) {
        secondsToNextHeart.value = 0;
        timeToNextHeartStr.value = '';
        return;
      }

      if (secondsToNextHeart.value > 1) {
        secondsToNextHeart.value--;
        timeToNextHeartStr.value = _formatDuration(secondsToNextHeart.value);
      } else {
        _checkAndRegenerate();
      }
    });
  }

  Future<bool> useHeart() async {
    if (isUnlimited.value) return true;

    if (currentHearts.value <= 0) {
      return false;
    }

    final wasMax = currentHearts.value >= maxHearts;
    currentHearts.value--;

    if (wasMax) {
      _lastRegenTime = DateTime.now();
    }

    _checkAndRegenerate();
    await _saveToStorage();
    return true;
  }

  /// Refill hearts to max capacity.
  Future<void> refillHearts() async {
    currentHearts.value = maxHearts;
    secondsToNextHeart.value = 0;
    timeToNextHeartStr.value = '';
    _lastRegenTime = DateTime.now();
    await _saveToStorage();
  }

  /// Helper to format seconds into MM:SS format.
  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
