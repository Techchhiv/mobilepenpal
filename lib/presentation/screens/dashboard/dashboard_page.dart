import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/config/app_constants.dart';
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
import 'package:mobilepenpal/presentation/widgets/home/randomly_floating_asset.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

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
    // Instantiate pages once here so they aren't recreated during state updates
    final page0 = _buildCourseTab(context, homeController, worldController, anim);
    final page1 = MiniGamePage();
    final page2 = QuestPage();
    final page3 = ShopPage();

    final List<Color> navColors = [
      const Color(0xFFFF6347), // Lessons (tomato red)
      const Color(0xFFFF793F), // Games (dark orange)
      const Color(0xFF845EF7), // Quests (purple)
      const Color(0xFFF57C00), // Shop (amber)
    ];

    return Obx(() {
      final isLoading =
          worldController.isLoading.value || homeController.isLoading.value;

      return LoadingOverlay(
        isLoading: isLoading,
        child: Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              AnimatedOpacity(
                opacity: navController.currentIndex.value == 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: IgnorePointer(
                  ignoring: navController.currentIndex.value != 0,
                  child: page0,
                ),
              ),
              AnimatedOpacity(
                opacity: navController.currentIndex.value == 1 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: IgnorePointer(
                  ignoring: navController.currentIndex.value != 1,
                  child: page1,
                ),
              ),
              AnimatedOpacity(
                opacity: navController.currentIndex.value == 2 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: IgnorePointer(
                  ignoring: navController.currentIndex.value != 2,
                  child: page2,
                ),
              ),
              AnimatedOpacity(
                opacity: navController.currentIndex.value == 3 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: IgnorePointer(
                  ignoring: navController.currentIndex.value != 3,
                  child: page3,
                ),
              ),
            ],
          ),
          bottomNavigationBar: Obx(() {
            final isStudent = homeController.currentMode.value == 'student';
            if (!isStudent) {
              return Container(
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
                      _buildNavItem(0, Icons.menu_book_rounded, 'nav_lessons'),
                      _buildNavItem(1, Icons.sports_esports_rounded, 'nav_games'),
                      _buildNavItem(2, Icons.bolt_rounded, 'nav_quests'),
                      _buildNavItem(3, Icons.storefront_rounded, 'nav_shop'),
                    ],
                  ),
                ),
              );
            }

            final activeColor = navColors[navController.currentIndex.value];


            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(
                left: 18,
                right: 18,
                bottom: 12 + MediaQuery.of(context).padding.bottom,
              ),
              height: 64,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF1E293B), width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF1E293B),
                    offset: Offset(0, 5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.menu_book_rounded, 'nav_lessons'),
                  _buildNavItem(1, Icons.sports_esports_rounded, 'nav_games'),
                  _buildNavItem(2, Icons.bolt_rounded, 'nav_quests'),
                  _buildNavItem(3, Icons.storefront_rounded, 'nav_shop'),
                ],
              ),
            );
          }),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 0.0),
            child: GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Get.back();
                } else {
                  Get.offAllNamed(AppRoutes.home);
                }
              },
              child: Obx(() {
                final activeColor = navColors[navController.currentIndex.value];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1E293B), width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF1E293B),
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                );
              }),
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
                          Color(0xFFE0F7FA), // Soft cartoon sky cyan
                          Color(0xFFFFF9C4), // Soft cartoon sky yellow
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

        Obx(() {
          final isStudent = homeController.currentMode.value == 'student';
          return Positioned.fill(
            child: AnimatedOpacity(
              opacity: isStudent ? 0.35 : 0.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: Image.asset(
                'assets/images/backgrounds/home_cartoon_background.png',
                fit: BoxFit.cover,
              ),
            ),
          );
        }),

        SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Obx(() {
                final isStudent = homeController.currentMode.value == 'student';
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: isStudent
                      ? const Stack(
                          key: ValueKey('student_decor'),
                          children: [
                            RandomlyFloatingAsset(
                              assetPath:
                                  'assets/images/illustrations/balloon.png',
                              width: 90,
                              minTop: 80,
                              maxTop: 450,
                              minLeft: -30,
                              maxLeft: 260,
                            ),
                            RandomlyFloatingAsset(
                              assetPath:
                                  'assets/images/decorations/cute_star_decor.png',
                              width: 48,
                              minTop: 120,
                              maxTop: 550,
                              minRight: -20,
                              maxRight: 240,
                            ),
                            RandomlyFloatingAsset(
                              assetPath: 'assets/images/illustrations/bird.png',
                              width: 65,
                              minTop: 220,
                              maxTop: 650,
                              minLeft: -30,
                              maxLeft: 260,
                            ),
                          ],
                        )
                      : Stack(
                          key: const ValueKey('parent_decor'),
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
                          ],
                        ),
                );
              }),

              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppConstants.globalMaxWidth,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Obx(() {
                          final isTabActive =
                              navController.currentIndex.value == 0;
                          return ProfileHeaderCard(
                            heroTag: isTabActive
                                ? 'hero_profile_header'
                                : 'hero_profile_header_tab_0',
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

  Widget _buildNavItem(int index, IconData icon, String labelKey) {
    final List<Color> navColors = [
      const Color(0xFFFF6347), // Lessons (tomato red)
      const Color(0xFFFF793F), // Games (dark orange)
      const Color(0xFF845EF7), // Quests (purple)
      const Color(0xFFF57C00), // Shop (amber)
    ];

    return Obx(() {
      final isSelected = navController.currentIndex.value == index;
      final isStudent = homeController.currentMode.value == 'student';

      if (!isStudent) {
        final iconColor = isSelected ? AppColors.primary : const Color(0xFF94A3B8);
        return Expanded(
          child: InkWell(
            onTap: () => navController.changePage(index),
            splashColor: AppColors.primary.withValues(alpha: 0.1),
            highlightColor: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 24),
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
            ),
          ),
        );
      }

      // Student Mode: Expanding capsule floating navigation item
      final activeColor = navColors[navController.currentIndex.value];

      return GestureDetector(
        onTap: () => navController.changePage(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: isSelected
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: isSelected
              ? BoxDecoration(
                  color: Colors.white, // Clean white capsule
                  borderRadius: BorderRadius.circular(999),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Text(
                  labelKey.tr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: activeColor, // Text matches active header/nav theme color
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
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
