import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/auth/auth_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/world/world_controller.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/presentation/screens/dashboard/parent_home.dart';
import 'package:mobilepenpal/presentation/screens/dashboard/student_home.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';
import 'package:mobilepenpal/data/controllers/dashboard/navigation_controller.dart';
import 'package:mobilepenpal/presentation/screens/mini_game/mini_game_page.dart';
import 'package:mobilepenpal/presentation/screens/quest/quest_page.dart';
import 'package:mobilepenpal/presentation/screens/shop/shop_page.dart';
import 'package:mobilepenpal/presentation/widgets/home/profile_header_card.dart';

class DashboardPage extends StatelessWidget {
  DashboardPage({super.key});

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
              MiniGamePage(),
              QuestPage(),
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
                  _buildNavItem(1, Icons.sports_esports_rounded),
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
                        child: Obx(() {
                          final isTabActive = navController.currentIndex.value == 0;
                          return ProfileHeaderCard(
                            heroTag: isTabActive ? 'hero_profile_header' : 'hero_profile_header_tab_0',
                            showCoin: false,
                          );
                        }),
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
