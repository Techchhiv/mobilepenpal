import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/core/config/app_constants.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/screens/ai_writing/ai_writing_page.dart';
import 'package:mobilepenpal/presentation/screens/dashboard/parent_home.dart';
import 'package:mobilepenpal/presentation/widgets/home/mode_switcher.dart';
import 'package:mobilepenpal/presentation/widgets/home/profile_header_card.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeController homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Fullscreen Schoolyard Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/home_background.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Main Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Profile Header Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppConstants.globalMaxWidth,
                    ),
                    child: const ProfileHeaderCard(),
                  ),
                ),

                // Scrollable Body Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppConstants.globalMaxWidth,
                        ),
                        child: Obx(() {
                          final isStudent =
                              homeController.currentMode.value == 'student';

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              );
                            },
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut,
                                ),
                                child: child,
                              );
                            },
                            child: isStudent
                                ? _buildStudentSection(context)
                                : _buildParentSection(context),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Fixed Bottom Role Selector (Parent / Student Switcher)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppConstants.globalMaxWidth,
                ),
                child: ModeSwitcher(
                  currentMode: homeController.currentMode,
                  onModeChanged: (mode) =>
                      homeController.requestModeChange(mode),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Student Section ---
  Widget _buildStudentSection(BuildContext context) {
    return Column(
      key: const ValueKey('student_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        // 1. Statistics Header & Cards
        _buildSectionHeader('statistics'.tr),
        const SizedBox(height: 10),
        _buildStatisticsCards(),
        const SizedBox(height: 20),

        // 2. Activities Header & 2-Column Cards
        _buildSectionHeader('activities'.tr),
        const SizedBox(height: 10),
        _buildActivitiesCards(context),
      ],
    );
  }

  // --- Parent Section ---
  Widget _buildParentSection(BuildContext context) {
    return Container(
      key: const ValueKey('parent_section'),
      child: ParentHome(
        homeController: homeController,
        isNested: true,
      ),
    );
  }

  // --- Section Header Title ---
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 0.3,
        shadows: [
          Shadow(
            color: Color(0xFF232A3B),
            blurRadius: 4,
            offset: Offset(0, 1.5),
          ),
          Shadow(
            color: Color(0x80000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }

  // --- Statistics Section: Streak and Coins ---
  Widget _buildStatisticsCards() {
    return Obx(() {
      final student = homeController.student.value;
      final streakVal = student?.streak ?? 0;
      final coinsVal = student?.coin ?? 0;

      return Row(
        children: [
          // Streak Card
          Expanded(
            child: _buildStatCard(
              title: 'streak'.tr,
              value: '$streakVal',
              icon: Icons.local_fire_department_rounded,
              iconColor: const Color(0xFFF97316),
              iconBgColor: const Color(0xFFFFEDD5),
            ),
          ),
          const SizedBox(width: 14),

          // Coins Card
          Expanded(
            child: _buildStatCard(
              title: 'coins'.tr,
              value: NumberFormatUtils.intText(coinsVal),
              icon: Icons.stars_rounded,
              iconColor: const Color(0xFFEAB308),
              iconBgColor: const Color(0xFFFEF9C3),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF232A3B), width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF232A3B),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF232A3B), width: 1.8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF232A3B),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Activities Section: My Lessons and My Writing ---
  Widget _buildActivitiesCards(BuildContext context) {
    return Row(
      children: [
        // 1. My Lessons
        Expanded(
          child: _buildActivityCard(
            title: 'my_lesson'.tr,
            actionText: 'action_learn'.tr,
            cardBgColor: const Color(0xFFF0F8F8),
            buttonColor: const Color(0xFF087D85),
            illustration: Lottie.asset(
              'assets/animated/pencil.json',
              height: 75,
              repeat: true,
            ),
            onTap: () => Get.toNamed(AppRoutes.dashboard),
          ),
        ),
        const SizedBox(width: 14),

        // 2. My Writing
        Expanded(
          child: _buildActivityCard(
            title: 'my_writing'.tr,
            actionText: 'action_draw'.tr,
            cardBgColor: const Color(0xFFFFF9EC),
            buttonColor: const Color(0xFFFF9D00),
            illustration: Lottie.asset(
              'assets/animated/star.json',
              height: 75,
              repeat: true,
            ),
            onTap: () => Get.to(() => const AiWritingPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String actionText,
    required Color cardBgColor,
    required Color buttonColor,
    required Widget illustration,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 215,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF232A3B), width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF232A3B),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: illustration,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF232A3B),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF232A3B), width: 1.8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF232A3B),
                    offset: Offset(0, 2.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                actionText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
