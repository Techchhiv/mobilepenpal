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
import 'package:mobilepenpal/presentation/widgets/home/mode_switcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mobilepenpal/data/controllers/home/navigation_controller.dart';
import 'package:mobilepenpal/presentation/screens/adventure/adventure_page.dart';
import 'package:mobilepenpal/presentation/screens/daily_challenge/daily_challenge_page.dart';
import 'package:mobilepenpal/presentation/screens/shop/shop_page.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeController homeController = Get.find<HomeController>();
  final AuthController authController = Get.find<AuthController>();
  final WorldController worldController = Get.find<WorldController>();
  final HomeAnimationController anim = Get.find<HomeAnimationController>();
  final NavigationController navController = Get.find<NavigationController>();

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
    return Obx(() {
      final isLoading =
          worldController.isLoading.value || homeController.isLoading.value;

      return LoadingOverlay(
        isLoading: isLoading,
        child: Scaffold(
          body: IndexedStack(
            index: navController.currentIndex.value,
            children: [
              _buildCourseTab(context, homeController, worldController, anim),
              AdventurePage(),
              DailyChallengePage(),
              ShopPage(),
            ],
          ),
          bottomNavigationBar: Container(
            height: 52 + MediaQuery.of(context).padding.bottom,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  _buildNavItem(0, Icons.menu_book_rounded),
                  _buildNavItem(1, Icons.explore_rounded),
                  _buildNavItem(2, Icons.bolt_rounded),
                  _buildNavItem(3, Icons.storefront_rounded),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCourseTab(
    BuildContext context,
    HomeController homeController,
    WorldController worldController,
    HomeAnimationController anim,
  ) {
    return Stack(
      children: [
        Obx(() {
          final isStudent = homeController.currentMode.value == 'student';

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Container(
              key: ValueKey<bool>(isStudent),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isStudent
                      ? const [
                          Color(0xFFF3FBFF),
                          Color(0xFFF7F8FF),
                          Color(0xFFFFF7F2),
                        ]
                      : const [
                          AppColors.primary,
                          Color(0xFF1e8c79),
                          Color(0xFF49aa7c),
                        ],
                ),
              ),
            ),
          );
        }),

        SafeArea(
          bottom: false,
          child: Stack(
            children: [
              _buildDecorRotatedSquareAnimated(
                anim: anim,
                left: -80,
                top: 75,
                phase: 0.10,
              ),
              _buildDecorRotatedSquareAnimated(
                anim: anim,
                right: -80,
                top: 140,
                phase: 0.10,
              ),
              _buildDecorRotatedSquareAnimated(
                anim: anim,
                right: -80,
                bottom: 50,
                phase: 0.10,
              ),

              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Env.globalMaxWidth,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Obx(
                          () => _buildHeroHeader(context, homeController),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildModeCard(homeController),
                      ),

                      const SizedBox(height: 12),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Obx(() {
                            final isStudent =
                                homeController.currentMode.value == 'student';

                            return IndexedStack(
                              index: isStudent ? 0 : 1,
                              children: [
                                StudentHome(homeController: homeController),
                                ParentHome(homeController: homeController),
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeader(BuildContext context, HomeController homeController) {
    final isStudent = homeController.currentMode.value == 'student';

    final isLoadingProfile =
        homeController.isProfileLoading.value &&
        homeController.student.value == null;

    final name = isStudent
        ? homeController.fullName
        : homeController.parentName;

    Widget shimmerBlock({
      required double width,
      required double height,
      double radius = 12,
    }) {
      return Shimmer.fromColors(
        baseColor: Colors.white.withValues(alpha: 0.22),
        highlightColor: Colors.white.withValues(alpha: 0.38),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );
    }

    Widget shimmerCircle(double size) {
      return Shimmer.fromColors(
        baseColor: Colors.white.withValues(alpha: 0.18),
        highlightColor: Colors.white.withValues(alpha: 0.34),
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                  child: isLoadingProfile
                      ? Center(child: shimmerCircle(46))
                      : _buildAvatarContent(homeController),
                ),
              ),

              const SizedBox(width: 12),

              // Text area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isStudent ? "👋 ${'welcome'.tr}" : "✨ ${'welcome'.tr}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    if (isLoadingProfile)
                      shimmerBlock(width: 170, height: 18, radius: 10)
                    else
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
                child: RepaintBoundary(
                  child: Lottie.asset(
                    'assets/animated/cat.json',
                    width: 72,
                    height: 72,
                    repeat: true,
                    animate: true,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),

        const Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(child: _SparklesOverlay()),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarContent(HomeController homeController) {
    final ShopAvatar? shopAvatar = homeController.currentShopAvatar;

    if (shopAvatar != null && shopAvatar.id != 'default') {
      if (shopAvatar.assetPath != null) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset(shopAvatar.assetPath!, fit: BoxFit.contain),
        );
      }
      return Icon(
        shopAvatar.icon ?? Icons.person,
        size: 34,
        color: Colors.white,
      );
    }

    return const Icon(Icons.person, size: 34, color: Colors.white);
  }

  Widget _buildNavItem(int index, IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: () => navController.changePage(index),
        splashColor: AppColors.primary.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        child: Obx(() {
          final isSelected = navController.currentIndex.value == index;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.grey.shade400,
                size: 28,
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildModeCard(HomeController homeController) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      // padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // color: Colors.white.withValues(alpha: 0.85),
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        // border: Border.all(
        //   color: Colors.white.withValues(alpha: 0.9),
        //   width: 1,
        // ),
      ),
      child: ModeSwitcher(
        currentMode: homeController.currentMode,
        onModeChanged: (mode) => homeController.requestModeChange(mode),
      ),
    );
  }

  Widget _buildDecorRotatedSquareAnimated({
    required HomeAnimationController anim,
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
        child: RepaintBoundary(
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
      ),
    );
  }
}

class _SparklesOverlay extends StatelessWidget {
  const _SparklesOverlay();

  @override
  Widget build(BuildContext context) {
    final HomeAnimationController anim = Get.find<HomeAnimationController>();

    return AnimatedBuilder(
      animation: anim.bubbleController,
      builder: (_, __) {
        return CustomPaint(
          painter: _BubblesPainter(anim, anim.bubbleController.value),
        );
      },
    );
  }
}

class _BubblesPainter extends CustomPainter {
  final HomeAnimationController anim;
  final double t;

  _BubblesPainter(this.anim, this.t);

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
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
