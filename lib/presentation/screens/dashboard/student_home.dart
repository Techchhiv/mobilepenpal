import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/localization/locale_controller.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/world/world_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/home/course_card.dart';
import 'package:mobilepenpal/presentation/widgets/world/heart_status_widget.dart';

class StudentHome extends StatelessWidget {
  final HomeController homeController;

  StudentHome({super.key, required this.homeController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = homeController.studentProgress;
      final loading = homeController.isProfileLoading.value && list.isEmpty;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
            child: Row(
              children: [
                const Text("📚  "),
                Expanded(
                  child: Text(
                    'my_course'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const HeartStatusWidget(),
                const SizedBox(width: 4),
                Obx(() {
                  final isBusy = homeController.isProfileLoading.value;
                  return IconButton(
                    onPressed: isBusy
                        ? null
                        : () async =>
                              await homeController.fetchStudentProfile(),
                    icon: isBusy
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).primaryColor,
                            ),
                          )
                        : Icon(
                            Icons.refresh_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                }),
              ],
            ),
          ),

          Expanded(
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
                          padding: const EdgeInsets.only(bottom: 110),
                          itemCount: list.length,
                          itemBuilder: (_, index) {
                            final progress = list[index];
                            final unlocked = progress.isUnlocked == true;
                            final locale = Get.find<LocaleController>();
                            final title = locale.isKhmer
                                ? (progress.name)
                                : (progress.nameEn);
                            final subtitle = locale.isKhmer
                                ? (progress.description)
                                : (progress.descriptionEn);

                            final Color primaryColor = _getColorByIndex(index);

                            String buttonLabel;
                            if (!unlocked) {
                              buttonLabel = 'locked'.tr;
                            } else if (progress.levelsCompleted > 0) {
                              buttonLabel = 'continue'.tr;
                            } else {
                              buttonLabel = 'start'.tr;
                            }

                            final cardBgColor =
                                AppColors.courseCardBgColors[index %
                                    AppColors.courseCardBgColors.length];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
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
                                bgColor: cardBgColor,
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
                        )),
          ),
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
