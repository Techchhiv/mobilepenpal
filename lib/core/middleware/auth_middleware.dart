import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  final box = GetStorage();

  @override
  RouteSettings? redirect(String? route) {
    final isLoggedIn = box.read('is_logged_in') == true;
    final hasToken = box.read('has_token') == true;

    final authed = isLoggedIn && hasToken;

    const publicRoutes = {AppRoutes.splash, AppRoutes.login, AppRoutes.otp};

    if (!authed && !publicRoutes.contains(route)) {
      return const RouteSettings(name: AppRoutes.login);
    }

    if (authed && publicRoutes.contains(route)) {
      return const RouteSettings(name: AppRoutes.home);
    }

    return null;
  }
}
