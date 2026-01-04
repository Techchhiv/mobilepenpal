import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class AuthGateMiddleware extends GetMiddleware {
  AuthGateMiddleware({this.priority = 0});

  @override
  final int priority;

  final box = GetStorage();

  bool get _hasToken {
    final t = box.read('token');
    return t != null && t.toString().trim().isNotEmpty;
  }

  bool _isPublic(String? route) {
    return route == AppRoutes.splash ||
        route == AppRoutes.login ||
        route == AppRoutes.otp;
  }

  @override
  RouteSettings? redirect(String? route) {
    final hasToken = _hasToken;
    final isPublic = _isPublic(route);

    // ✅ Logged out: only allow public routes
    if (!hasToken && !isPublic) {
      return const RouteSettings(name: AppRoutes.login);
    }

    // ✅ Logged in: block public routes
    if (hasToken && isPublic) {
      return const RouteSettings(name: AppRoutes.home);
    }

    return null; // allow
  }
}
