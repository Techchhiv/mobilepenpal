import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';

class AiWritingPage extends StatelessWidget {
  const AiWritingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();
    final bool isStudent = homeController.currentMode.value == 'student';

    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Back Button bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: isStudent ? const Color(0xFF1E293B) : Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: isStudent
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.15),
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Illustrated Circle
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isStudent
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.draw_rounded,
                            size: 64,
                            color: isStudent ? AppColors.primary : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'my_writing'.tr,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: isStudent ? const Color(0xFF1E293B) : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Coming Soon Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'Coming Soon',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Description Box
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: isStudent ? 0.9 : 0.1),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isStudent
                                ? Colors.grey.shade200
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                          boxShadow: isStudent
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'writing_coming_soon'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                                color: isStudent
                                    ? const Color(0xFF334155)
                                    : Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildFeatureRow(
                              icon: Icons.gesture_rounded,
                              text: 'Practice tracing Khmer characters',
                              isStudent: isStudent,
                            ),
                            const SizedBox(height: 12),
                            _buildFeatureRow(
                              icon: Icons.psychology_rounded,
                              text: 'Get instant AI accuracy feedback',
                              isStudent: isStudent,
                            ),
                            const SizedBox(height: 12),
                            _buildFeatureRow(
                              icon: Icons.emoji_events_rounded,
                              text: 'Earn coins and unlock writing achievements',
                              isStudent: isStudent,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String text,
    required bool isStudent,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isStudent ? AppColors.primary : const Color(0xFF2EC4B6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isStudent ? const Color(0xFF475569) : Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}
