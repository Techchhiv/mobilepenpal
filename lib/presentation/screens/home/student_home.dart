import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/localization/locale_controller.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/world/world_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/home/course_card.dart';

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
                  : (list.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            children: [
                              SizedBox(height: 140),
                              Icon(
                                Icons.menu_book_outlined,
                                size: 56,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Center(
                                child: Text(
                                  "no_course_available".tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              SizedBox(height: 6),
                              Center(
                                child: Text(
                                  "pull_down_to_refresh".tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: list.length,
                            itemBuilder: (_, index) {
                              final progress = list[index];
                              final unlocked = progress.isUnlocked == true;
                              final isSubLocked =
                                  progress.isLockedBySubscription;
                              final locale = Get.find<LocaleController>();
                              final title = locale.isKhmer
                                  ? (progress.name)
                                  : (progress.nameEn);
                              final subtitle = locale.isKhmer
                                  ? (progress.description)
                                  : (progress.descriptionEn);

                              // Subscription-locked worlds: visible but tapping shows upgrade prompt
                              final Color primaryColor = isSubLocked
                                  ? const Color(0xFFB8860B)
                                  : _getColorByIndex(index);

                              String buttonLabel;
                              if (isSubLocked) {
                                buttonLabel = '👑 ${'subscribe'.tr}';
                              } else if (!unlocked) {
                                buttonLabel = 'locked'.tr;
                              } else if (progress.levelsCompleted > 0) {
                                buttonLabel = 'continue'.tr;
                              } else {
                                buttonLabel = 'start'.tr;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: CourseCard(
                                  courseTitle: title,
                                  courseSubtitle: subtitle,
                                  badgeText: progress.isCompleted
                                      ? 'completed'.tr
                                      : 'in_progress'.tr,
                                  completedLessons: progress.levelsCompleted,
                                  totalLessons: progress.levelsTotal,
                                  buttonText: buttonLabel,
                                  primaryColor: primaryColor,
                                  badgeColor: progress.isCompleted
                                      ? Colors.green
                                      : const Color(0xFFFF9800),
                                  onTap: isSubLocked
                                      ? () => _showSubscriptionPrompt()
                                      : (unlocked
                                            ? () => _openWorld(progress.id)
                                            : null),
                                  isLocked: !unlocked && !isSubLocked,
                                ),
                              );
                            },
                          )),
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

  void _showSubscriptionPrompt() {
    Get.snackbar(
      '👑 ${'premium_content'.tr}',
      'subscribe_to_unlock'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFB8860B),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.lock_outline, color: Colors.white),
    );
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
