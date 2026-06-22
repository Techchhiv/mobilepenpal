import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/home/home_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/home/mode_switcher.dart';
import 'package:mobilepenpal/presentation/widgets/home/parent_summary_page.dart';
import 'package:mobilepenpal/presentation/widgets/home/profile_header_card.dart';
import 'package:mobilepenpal/presentation/screens/dashboard/parent_home.dart';
import 'package:mobilepenpal/presentation/screens/ai_writing/ai_writing_page.dart';
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
          child: Stack(
            children: [
              // Rotating square animations from dashboard
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

              SafeArea(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets
                      .zero, // Zero out parent padding to control individual element margins exactly
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: Env.globalMaxWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(
                            height: 12,
                          ), // Exact match to top margin of DashboardPage
                          // User Info Card (copied from Dashboard Hero Header with sparkles)
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

                          // Content based on mode (Student shows stats & navigation, Parent shows embedded dashboard)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Obx(() {
                              final isStudent =
                                  homeController.currentMode.value == 'student';
                              if (isStudent) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildExtraInfoSection(context),
                                    const SizedBox(height: 24),
                                    _buildNavigationSection(context),
                                    const SizedBox(height: 20),
                                  ],
                                );
                              } else {
                                return ParentHome(
                                  homeController: homeController,
                                  isNested: true,
                                );
                              }
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
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

    Widget statItem({
      required String title,
      required String value,
      required IconData icon,
      required Color color,
      required List<Color> gradientColors,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
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
              color: Colors.orange,
              gradientColors: [Colors.orange, Colors.redAccent],
            ),
            const SizedBox(width: 12),
            statItem(
              title: 'coins'.tr,
              value: '$coinsVal',
              icon: Icons.monetization_on_rounded,
              color: Colors.amber.shade700,
              gradientColors: [Colors.amber, Colors.orangeAccent],
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
    final isStudent = homeController.currentMode.value == 'student';

    Widget navButton({
      required String title,
      required String subtitle,
      required IconData icon,
      required Color primaryColor,
      required Color secondaryColor,
      required VoidCallback onTap,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, secondaryColor],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
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
            'activities'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isStudent ? const Color(0xFF1E293B) : Colors.white,
            ),
          ),
        ),
        navButton(
          title: 'my_lesson'.tr,
          subtitle: isStudent
              ? 'my_lesson_student_desc'.tr
              : 'my_lesson_parent_desc'.tr,
          icon: Icons.menu_book_rounded,
          primaryColor: isStudent
              ? const Color(0xFF0D9488)
              : const Color(0xFF006D5B),
          secondaryColor: isStudent
              ? const Color(0xFF0F766E)
              : const Color(0xFF0F4C43),
          onTap: () => Get.toNamed(AppRoutes.dashboard),
        ),
        navButton(
          title: 'my_writing'.tr,
          subtitle: isStudent
              ? 'my_writing_student_desc'.tr
              : 'my_writing_parent_desc'.tr,
          icon: Icons.draw_rounded,
          primaryColor: isStudent
              ? const Color(0xFF2563EB)
              : const Color(0xFF1D4ED8),
          secondaryColor: isStudent
              ? const Color(0xFF1D4ED8)
              : const Color(0xFF1E3A8A),
          onTap: () => Get.to(() => const AiWritingPage()),
        ),
      ],
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

