import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/world/world_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/course_card.dart';

class StudentHome extends StatelessWidget {
  final HomeController homeController;

 StudentHome({super.key, required this.homeController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = homeController.isProfileLoading.value;
      final list = homeController.studentProgress;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
            child: Row(
              children: [
                const Text("📚  "),
                Text(
                  'my_course'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => await homeController.refreshHome(),
              child: loading
                  ? ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: 2,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 14),
                        child: CourseCard(isLoading: true),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: list.length,
                      itemBuilder: (_, index) {
                        final progress = list[index];
                        final unlocked = progress.isUnlocked == true;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: CourseCard(
                            courseTitle: progress.name,
                            courseSubtitle: progress.description,
                            badgeText: progress.isCompleted
                                ? 'completed'.tr
                                : 'in_progress'.tr,
                            completedLessons: progress.levelsCompleted,
                            totalLessons: progress.levelsTotal,
                            buttonText: unlocked
                                ? (progress.levelsCompleted > 0
                                      ? 'continue'.tr
                                      : 'start'.tr)
                                : 'locked'.tr,
                            primaryColor: _getColorByIndex(index),
                            badgeColor: progress.isCompleted
                                ? Colors.green
                                : const Color(0xFFFF9800),
                            onTap: unlocked
                                ? () => _openWorld(progress.id)
                                : null,
                            isLocked: !unlocked,
                          ),
                        );
                      },
                    ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      );
    });
  }

  Future<void> _openWorld(int worldId) async {
    final worldController = Get.find<WorldController>();

    await worldController.fetchWorldById(worldId);
    final world = worldController.currentWorld.value;

    if (world != null && world.id == worldId) {
      final route = RouteBuilder.build(AppRoutes.world, {
        'id': worldId.toString(),
      });
      Get.toNamed(route);
    } else {
      Get.snackbar(
        'Error',
        'Failed to load course'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  final List<Color> _courseColors = [
    Color(0xFF49aa7c),
    Color(0xFF6EC6FF),
    Color(0xFFFFC857),
    Color(0xFFFF8A80),
    Color(0xFF81C784),
    Color(0xFFBA68C8),
    Color(0xFF4DD0E1),
  ];

  Color _getColorByIndex(int index) {
    return _courseColors[index % _courseColors.length];
  }
}
