import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class NetworkController extends GetxController {
  final box = GetStorage();

  final RxBool isOnline = true.obs;
  final RxBool isChecking = false.obs;

  StreamSubscription<InternetStatus>? _sub;

  Timer? _offlineDebounce;

  static const Duration _offlineGrace = Duration(seconds: 5);

  static const int _failStreakToOffline = 2;
  bool _isDialogOpen = false;

  late final InternetConnection _connection = InternetConnection.createInstance(
    customCheckOptions: [
      InternetCheckOption(
        uri: Uri.parse('https://www.google.com/generate_204'),
        timeout: const Duration(seconds: 6),
        responseStatusFn: (r) => r.statusCode == 204,
      ),
      InternetCheckOption(
        uri: Uri.parse('https://clients3.google.com/generate_204'),
        timeout: const Duration(seconds: 6),
        responseStatusFn: (r) => r.statusCode == 204,
      ),
      InternetCheckOption(
        uri: Uri.parse('https://www.cloudflare.com/cdn-cgi/trace'),
        timeout: const Duration(seconds: 6),
        responseStatusFn: (r) => r.statusCode == 200,
      ),

      InternetCheckOption(
        uri: Uri.parse(Env.apiBaseUrl).resolve('student/v01/health'),
        timeout: const Duration(seconds: 8),
        responseStatusFn: (r) => r.statusCode >= 200 && r.statusCode < 500,
      ),
    ],
  );

  @override
  void onInit() {
    super.onInit();
    _start();
  }

  Future<void> _start() async {
    await recheck();

    _sub = _connection.onStatusChange.listen((status) {
      final connected = status == InternetStatus.connected;

      if (connected) {
        _offlineDebounce?.cancel();
        _offlineDebounce = null;

        if (!isOnline.value) {
          isOnline.value = true;
          _handleHardBlockRouting();
        }
        return;
      }

      _offlineDebounce?.cancel();
      _offlineDebounce = Timer(_offlineGrace, () async {
        final ok = await _confirmInternetWithStreak();
        isOnline.value = ok;
        _handleHardBlockRouting();
      });
    });
  }

  Future<bool> recheck() async {
    isChecking.value = true;
    try {
      final ok = await _confirmInternetWithStreak(force: true);
      isOnline.value = ok;
      _handleHardBlockRouting();
      return ok;
    } finally {
      isChecking.value = false;
    }
  }

  Future<bool> _confirmInternetWithStreak({bool force = false}) async {
    if (force) {
      return await _connection.hasInternetAccess;
    }

    for (int i = 0; i < _failStreakToOffline; i++) {
      final ok = await _connection.hasInternetAccess;
      if (ok) {
        return true;
      }
      if (i < _failStreakToOffline - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return false;
  }

  void _handleHardBlockRouting() {
    final route = Get.currentRoute;

    if (!isOnline.value) {
      if (route != AppRoutes.splash && !_isDialogOpen) {
        _isDialogOpen = true;
        Get.dialog(
          PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      'no_internet_title'.tr == 'no_internet_title' ? 'No Internet Connection' : 'no_internet_title'.tr,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'no_internet_msg'.tr == 'no_internet_msg' ? 'Please check your connection and try again.' : 'no_internet_msg'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          barrierDismissible: false,
          barrierColor: Colors.black54,
        );
      }
      return;
    }

    if (isOnline.value && _isDialogOpen) {
      _isDialogOpen = false;
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    _offlineDebounce?.cancel();
    super.onClose();
  }
}
