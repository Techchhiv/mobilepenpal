import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/app_constants.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/home/home_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/home/mode_switcher.dart';
import 'package:mobilepenpal/presentation/widgets/home/parent_summary_page.dart';
import 'package:mobilepenpal/presentation/widgets/home/profile_header_card.dart';
import 'package:mobilepenpal/presentation/widgets/home/randomly_floating_asset.dart';
import 'package:mobilepenpal/presentation/screens/dashboard/parent_home.dart';
import 'package:mobilepenpal/presentation/screens/ai_writing/ai_writing_page.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeController homeController = Get.find<HomeController>();
  final HomeAnimationController anim = Get.find<HomeAnimationController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final isStudent = homeController.currentMode.value == 'student';

        return AnimatedContainer(
          width: double.infinity,
          height: double.infinity,
          duration: const Duration(milliseconds: 300),
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
          child: Stack(
            children: [
              // Playful Background for Student (fades smoothly in and out)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: isStudent ? 0.35 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  child: Image.asset(
                    'assets/images/backgrounds/home_cartoon_background.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Background decorations switcher (transitions floating cartoon assets to rotated squares)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: isStudent
                    ? const Stack(
                        key: ValueKey('student_decor'),
                        children: [
                          RandomlyFloatingAsset(
                            assetPath: 'assets/images/illustrations/balloon.png',
                            width: 90,
                            minTop: 80,
                            maxTop: 450,
                            minLeft: -30,
                            maxLeft: 260,
                          ),
                          RandomlyFloatingAsset(
                            assetPath: 'assets/images/decorations/cute_star_decor.png',
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
              ),

              SafeArea(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppConstants.globalMaxWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          // User Info Card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const ProfileHeaderCard(),
                          ),
                          const SizedBox(height: 20),

                          // Mode Switcher
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildModeCard(),
                          ),
                          const SizedBox(height: 20),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Obx(() {
                              final isStudent =
                                  homeController.currentMode.value == 'student';
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                switchInCurve: Curves.easeOutBack,
                                switchOutCurve: Curves.easeIn,
                                layoutBuilder:
                                    (currentChild, previousChildren) {
                                      return Stack(
                                        alignment: Alignment.topCenter,
                                        children: [
                                          ...previousChildren,
                                          if (currentChild != null)
                                            currentChild,
                                        ],
                                      );
                                    },
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.0, 0.06),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: isStudent
                                    ? Column(
                                        key: const ValueKey('student_content'),
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _buildExtraInfoSection(context),
                                          const SizedBox(height: 24),
                                          _buildNavigationSection(context),
                                          const SizedBox(height: 24),
                                        ],
                                      )
                                    : ParentHome(
                                        key: const ValueKey('parent_content'),
                                        homeController: homeController,
                                        isNested: true,
                                      ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildModeCard() {
    final isStudent = homeController.currentMode.value == 'student';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: isStudent
            ? Border.all(color: const Color(0xFF1E293B), width: 3)
            : null,
        boxShadow: isStudent
            ? const [
                BoxShadow(
                  color: Color(0xFF1E293B),
                  offset: Offset(0, 6),
                  blurRadius: 0,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ModeSwitcher(
        currentMode: homeController.currentMode,
        onModeChanged: (mode) => homeController.requestModeChange(mode),
      ),
    );
  }

  Widget _buildExtraInfoSection(BuildContext context) {
    final isStudent = homeController.currentMode.value == 'student';

    if (isStudent) {
      return _buildStudentStats();
    } else {
      return _buildParentSummarySection();
    }
  }

  Widget _buildStudentStats() {
    final student = homeController.student.value;
    final coinsVal = student?.coin ?? 0;
    final streakVal = student?.streak ?? 0;
    final darkBorderColor = const Color(0xFF1E293B);

    Widget statItem({
      required String title,
      required String value,
      required IconData icon,
      required Color bgColor,
      required Color accentColor,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: darkBorderColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: darkBorderColor,
                offset: const Offset(0, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: darkBorderColor, width: 2),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'statistics'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        Row(
          children: [
            statItem(
              title: 'streak'.tr,
              value: '$streakVal',
              icon: Icons.local_fire_department_rounded,
              bgColor: const Color(0xFFFFF3E0), // Playful peach
              accentColor: Colors.orange.shade700,
            ),
            const SizedBox(width: 16),
            statItem(
              title: 'coins'.tr,
              value: '$coinsVal',
              icon: Icons.stars_rounded,
              bgColor: const Color(0xFFFFFDE7), // Playful yellow
              accentColor: Colors.amber.shade700,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParentSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        ParentSummaryCard(homeController: homeController),
      ],
    );
  }

  Widget _buildNavigationSection(BuildContext context) {
    final darkBorderColor = const Color(0xFF1E293B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'activities'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        Row(
          children: [
            _buildActivityCard(
              title: 'my_lesson'.tr,
              subtitle: 'my_lesson_student_desc'.tr,
              actionText: 'action_learn'.tr,
              bgColor: const Color(0xFFE0F2F1), // Soft teal
              buttonColor: const Color(0xFF009688), // Solid teal
              darkBorderColor: darkBorderColor,
              onTap: () => Get.toNamed(AppRoutes.dashboard),
              illustration: Lottie.asset(
                'assets/animated/pencil.json',
                height: 75,
                repeat: true,
              ),
            ),
            const SizedBox(width: 16),
            _buildActivityCard(
              title: 'my_writing'.tr,
              subtitle: 'my_writing_student_desc'.tr,
              actionText: 'action_draw'.tr,
              bgColor: const Color(0xFFFFF3E0), // Soft orange
              buttonColor: const Color(0xFFFF9800), // Solid orange
              darkBorderColor: darkBorderColor,
              onTap: () => Get.to(() => const AiWritingPage()),
              illustration: Lottie.asset(
                'assets/animated/star.json',
                height: 75,
                repeat: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String subtitle,
    required String actionText,
    required Color bgColor,
    required Color buttonColor,
    required Color darkBorderColor,
    required VoidCallback onTap,
    Widget? illustration,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 195,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: darkBorderColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: darkBorderColor,
                offset: const Offset(0, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Opacity(
                    opacity: 0.08,
                    child: Icon(
                      Icons.school_rounded,
                      size: 90,
                      color: darkBorderColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Center(
                          child: illustration ?? const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: buttonColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: darkBorderColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: darkBorderColor,
                              offset: const Offset(0, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            actionText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
