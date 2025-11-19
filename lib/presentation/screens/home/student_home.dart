import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/presentation/widgets/achievement_card.dart';
import 'package:mobilepenpal/presentation/widgets/course_card.dart';

class StudentHome extends StatelessWidget {
  final HomeController homeController;

  const StudentHome({super.key, required this.homeController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'my_course'.tr,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Obx(() {
          if (homeController.isProfileLoading.value) {
            return Column(
              children: List.generate(
                2,
                (_) => const CourseCard(isLoading: true),
              ),
            );
          }

          if (homeController.studentProgress.isEmpty) {
            return _buildFallbackCourses();
          }

          return Column(
            children: homeController.studentProgress.map((progress) {
              return CourseCard(
                courseTitle: progress.worldName,
                courseSubtitle: progress.worldDescription,
                badgeText: progress.isCompleted
                    ? 'completed'.tr
                    : 'in_progress'.tr,
                completedLessons: progress.completedStages,
                totalLessons: progress.totalStages,
                buttonText: progress.completedStages > 0
                    ? 'continue'.tr
                    : 'start'.tr,
                primaryColor: _getColorForWorld(progress.worldId),
                badgeColor: progress.isCompleted
                    ? Colors.green
                    : const Color(0xFFFF9800),
                onTap: () {},
              );
            }).toList(),
          );
        }),

        const SizedBox(height: 18),

        Text(
          'achievements'.tr,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        
        const SizedBox(height: 18),

        AchievementCard(
          backgroundColor: Color(0xFFF0FDF4),
          borderColor:  Color(0xFF2EC4B6),
          icon: Icons.emoji_events,
          iconBackgroundColor: Color(0xFF00C950),
          iconSize: 24,
          title: 'លំហាត់គណិត', 
          subtitle:
              'បញ្ចប់មេរៀនគណិត ១០ មេរៀន',
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          subtitleStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
          onTap: () {
            Get.snackbar(
              'Achievement'.tr,
              'Fast Learner achievement details'.tr,
            );
          },
          borderRadius: 12,
          padding: const EdgeInsets.all(16),
          margin: EdgeInsets.zero,
          borderWidth: 2.0,
        ),
      ],
    );
  }

  Widget _buildFallbackCourses() {
    return Column(
      children: [
        CourseCard(
          courseTitle: 'រៀនអក្សរ',
          courseSubtitle: 'រៀនសរសេរអក្សរខ្មែរ',
          badgeText: 'in_progress'.tr,
          completedLessons: 9,
          totalLessons: 20,
          buttonText: 'continue'.tr,
          primaryColor: const Color(0xFFE91E63),
          badgeColor: const Color(0xFFFF9800),
          onTap: () {},
        ),
        const SizedBox(height: 16),
        CourseCard(
          courseTitle: 'រៀនលេខ',
          courseSubtitle: 'ការអនុវត្តន៍លំហាត់គណិត',
          badgeText: 'in_progress'.tr,
          completedLessons: 5,
          totalLessons: 15,
          buttonText: 'continue'.tr,
          primaryColor: const Color(0xFF2196F3),
          badgeColor: const Color(0xFFFF9800),
          onTap: () {},
        ),
      ],
    );
  }

  Color _getColorForWorld(int worldId) {
    switch (worldId) {
      case 1:
        return const Color(0xFFE91E63);
      case 2:
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }
}
