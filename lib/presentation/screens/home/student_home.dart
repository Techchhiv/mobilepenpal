import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/world/world_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/course_card.dart';

class StudentHome extends StatelessWidget {
  final HomeController homeController;

  const StudentHome({super.key, required this.homeController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = homeController.isProfileLoading.value;
      final list = homeController.studentProgress;

      return RefreshIndicator(
        onRefresh: () async => await homeController.refreshHome(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
              child: Row(
                children: [
                  const Text("📚  "),
                  Text(
                    'my_course'.tr,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),

            if (loading)
              ...List.generate(
                2,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: CourseCard(isLoading: true),
                ),
              )
            else
              ...List.generate(list.length, (index) {
                final progress = list[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: CourseCard(
                    courseTitle: progress.name,
                    courseSubtitle: progress.description,
                    badgeText: progress.isCompleted ? 'completed'.tr : 'in_progress'.tr,
                    completedLessons: progress.levelsCompleted,
                    totalLessons: progress.levelsTotal,
                    buttonText: progress.levelsCompleted > 0 ? 'continue'.tr : 'start'.tr,
                    primaryColor: _getColorForWorld(progress.id),
                    badgeColor: progress.isCompleted ? Colors.green : const Color(0xFFFF9800),
                    onTap: () => _openWorld(progress.id),
                  ),
                );
              }),

            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }

  Widget _buildHeroContinueCard({
    required bool loading,
    required bool hasCourse,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: (loading || !hasCourse) ? null : onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.95),
              color.withValues(alpha: 0.65),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loading ? "..." : "✨ ${'continue'.tr}",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loading ? "Loading..." : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loading ? "" : subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text("GO", style: TextStyle(fontWeight: FontWeight.w900)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWorld(int worldId) async {
    final worldController = Get.find<WorldController>();

    await worldController.fetchWorldById(worldId);
    final world = worldController.currentWorld.value;

    if (world != null && world.id == worldId) {
      final route = RouteBuilder.build(
        AppRoutes.world,
        {'id': worldId.toString()},
      );
      Get.toNamed(route);
    } else {
      Get.snackbar('Error', 'Failed to load course'.tr, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Color _getColorForWorld(int worldId) {
    switch (worldId) {
      case 1:
        return AppColors.buttonPrimary;
      case 2:
        return const Color(0xFF6EC6FF);
      default:
        return const Color(0xFFFFC857);
    }
  }
}
