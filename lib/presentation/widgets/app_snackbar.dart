import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/auth/network_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class AppSnackbar {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void show(
    String message, {
    String? title,
    Color backgroundColor = Colors.black87,
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    if (Get.isRegistered<NetworkController>()) {
      final network = Get.find<NetworkController>();
      if (!network.isOnline.value && Get.currentRoute != AppRoutes.offline) {
        return;
      }
    }

    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        content: Text(
          (title == null || title.isEmpty) ? message : '$title: $message',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
