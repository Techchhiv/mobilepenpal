import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  final box = GetStorage();

  @override
  RouteSettings? redirect(String? route) {
    final isLoggedIn = box.read('is_logged_in') == true;

    const publicRoutes = {
      AppRoutes.splash,
      AppRoutes.login,
      AppRoutes.otp,
    };

    if (!isLoggedIn && !publicRoutes.contains(route)) {
      return const RouteSettings(name: AppRoutes.login);
    }

    if (isLoggedIn && publicRoutes.contains(route)) {
      return const RouteSettings(name: AppRoutes.home);
    }

    return null;
  }
}
