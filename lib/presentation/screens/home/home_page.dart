import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:get_storage/get_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/auth/auth_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/world/world_controller.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/presentation/screens/home/parent_home.dart';
import 'package:mobilepenpal/presentation/screens/home/student_home.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';
import 'package:mobilepenpal/presentation/widgets/mode_switcher.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeController homeController = Get.find<HomeController>();
  final AuthController authController = Get.find<AuthController>();
  final WorldController worldController = Get.find<WorldController>();
  final HomeAnimationController anim = Get.find<HomeAnimationController>();

  final box = GetStorage();

  Student? get student {
    final studentData = box.read('student');
    if (studentData != null && studentData is Map<String, dynamic>) {
      return Student.fromJson(studentData);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => LoadingOverlay(
          isLoading: worldController.isLoading.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeInOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: homeController.currentMode.value == 'student'
                    ? [
                        Color(0xFFF3FBFF),
                        Color(0xFFF7F8FF),
                        Color(0xFFFFF7F2),
                      ]
                    : [
                        AppColors.primary,
                        Color(0xFF1e8c79),
                        Color(0xFF49aa7c),
                      ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  _buildDecorRotatedSquareAnimated(
                    left: -80,
                    top: 75,
                    phase: 0.10,
                  ),

                  _buildDecorRotatedSquareAnimated(
                    right: -80,
                    top: 140,
                    phase: 0.1,
                  ),

                  _buildDecorRotatedSquareAnimated(
                    right: -80,
                    bottom: 50,
                    phase: 0.1,
                  ),

                  Column(
                    children: [
                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildHeroHeader(context),
                      ),

                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildModeCard(),
                      ),

                      const SizedBox(height: 12),

                      // content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: homeController.currentMode.value == 'student'
                              ? StudentHome(homeController: homeController)
                              : ParentHome(homeController: homeController),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final isStudent = homeController.currentMode.value == 'student';
    final name = isStudent
        ? homeController.fullName
        : homeController.parentName;

    return Stack(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: homeController.avatarUrl.isNotEmpty
                      ? Image.network(
                          Env.backendUrl + homeController.avatarUrl,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.person, size: 34, color: Colors.white),
                ),
              ),

              const SizedBox(width: 12),

              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isStudent ? "👋 " + "welcome".tr : "✨ " + "welcome".tr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Lottie.asset(
                  'assets/animated/cat.json',
                  width: 72,
                  height: 72,
                  repeat: true,
                  animate: true,
                  fit: BoxFit.cover,
                  frameRate: FrameRate.max,
                ),
              ),
            ],
          ),
        ),

        Positioned.fill(child: IgnorePointer(child: _SparklesOverlay())),
      ],
    );
  }

  Widget _buildModeCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1,
        ),
      ),
      child: ModeSwitcher(
        currentMode: homeController.currentMode,
        onModeChanged: (mode) => homeController.requestModeChange(mode),
      ),
    );
  }

  Widget _buildDecorRotatedSquareAnimated({
    double? left,
    double? top,
    double? right,
    double? bottom,

    double size = 148,
    double radius = 43.48,
    double baseAngleDeg = 45,
    double opacity = 0.8,
    Color color = const Color(0x99FFA500),

    double floatPx = 8,
    double breathe = 0.03,
    double wiggleDeg = 2.0,
    double phase = 0.0,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: anim.bubbleController,
          builder: (_, __) {
            final t = (anim.bubbleController.value + phase) * 2 * math.pi;

            final dy = math.sin(t) * floatPx;
            final s = 1.0 + (math.sin(t + math.pi / 2) * breathe);
            final wiggleRad = (math.sin(t) * wiggleDeg) * math.pi / 180;
            final baseRad = baseAngleDeg * math.pi / 180;

            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.rotate(
                angle: baseRad + wiggleRad,
                child: Transform.scale(
                  scale: s,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(radius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SparklesOverlay extends StatelessWidget {
  final HomeAnimationController anim = Get.find<HomeAnimationController>();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim.bubbleController,
      builder: (_, __) {
        return CustomPaint(painter: _BubblesPainter(anim));
      },
    );
  }
}

class _BubblesPainter extends CustomPainter {
  final HomeAnimationController anim;

  _BubblesPainter(this.anim);

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in anim.bubbles) {
      final u = anim.bubbleU(b);
      final a = anim.bubbleAlphaFromU(u);

      final dx = b.x * size.width;
      final dy = (b.y * size.height) + anim.bubbleYOffsetFromU(u);

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: a)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), b.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) => true;
}
