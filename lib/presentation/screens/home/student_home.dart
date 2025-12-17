import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/world/world_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: Obx(() {
            return RefreshIndicator(
              onRefresh: () async => await homeController.refreshHome(),
              child: homeController.isProfileLoading.value
                  ? ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: 2,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 16),
                      itemBuilder: (_, __) =>
                          const CourseCard(isLoading: true),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: homeController.studentProgress.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final progress =
                            homeController.studentProgress[index];

                        return CourseCard(
                          courseTitle: progress.name,
                          courseSubtitle: progress.description,
                          badgeText: progress.isCompleted
                              ? 'completed'.tr
                              : 'in_progress'.tr,
                          completedLessons: progress.levelsCompleted,
                          totalLessons: progress.levelsTotal,
                          buttonText: progress.levelsCompleted > 0
                              ? 'continue'.tr
                              : 'start'.tr,
                          primaryColor:
                              _getColorForWorld(progress.id),
                          badgeColor: progress.isCompleted
                              ? Colors.green
                              : const Color(0xFFFF9800),
                          onTap: () async {
                            final worldController =
                                Get.find<WorldController>();

                            await worldController
                                .fetchWorldById(progress.id);

                            final world =
                                worldController.currentWorld.value;
                            if (world != null &&
                                world.id == progress.id) {
                              final route =
                                  RouteBuilder.build(AppRoutes.world, {
                                'id': progress.id.toString(),
                              });

                              Get.toNamed(
                                route,
                                arguments: {
                                  'color': _getColorForWorld(progress.id).value,
                                },
                              );
                            } else {
                              Get.snackbar(
                                'Error',
                                'Failed to load course'.tr,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                        );
                      },
                    ),
            );
          }),
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
