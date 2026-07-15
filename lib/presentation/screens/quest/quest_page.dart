import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/app_constants.dart';
import 'package:mobilepenpal/data/controllers/quest/quest_controller.dart';
import 'package:mobilepenpal/presentation/widgets/quest/quest_card.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';
import 'package:mobilepenpal/data/controllers/dashboard/navigation_controller.dart';
import 'package:mobilepenpal/presentation/widgets/home/profile_header_card.dart';
import 'package:mobilepenpal/presentation/widgets/home/randomly_floating_asset.dart';
import 'package:mobilepenpal/presentation/widgets/animated_button.dart';

/// The main Quest screen that replaces the old Daily Challenge page.
///
/// Layout:
///   1. Top header with title + daily progress ring
///   2. Scrollable list of [QuestCard] widgets
///   3. Bonus section (separated visually)
///   4. Empty state when no quests are available
class QuestPage extends GetView<QuestController> {
  const QuestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => LoadingOverlay(
        isLoading: controller.isStartingQuest.value,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE0F7FA), // Soft cartoon sky cyan
                Color(0xFFFFF9C4), // Soft cartoon sky yellow
              ],
            ),
          ),
          child: Stack(
            children: [
              // Landscape cartoon background image overlay
              Positioned.fill(
                child: Opacity(
                  opacity: 0.35,
                  child: Image.asset(
                    'assets/images/backgrounds/quest_cartoon_background.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Randomly floating cartoon decors
              const RandomlyFloatingAsset(
                assetPath: 'assets/images/illustrations/balloon.png',
                width: 90,
                minTop: 80,
                maxTop: 450,
                minLeft: -30,
                maxLeft: 260,
              ),
              const RandomlyFloatingAsset(
                assetPath: 'assets/images/decorations/cute_star_decor.png',
                width: 48,
                minTop: 120,
                maxTop: 550,
                minRight: -20,
                maxRight: 240,
              ),
              const RandomlyFloatingAsset(
                assetPath: 'assets/images/illustrations/bird.png',
                width: 65,
                minTop: 220,
                maxTop: 650,
                minLeft: -30,
                maxLeft: 260,
              ),

              SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppConstants.globalMaxWidth,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Obx(() {
                            final navController =
                                Get.find<NavigationController>();
                            final isTabActive =
                                navController.currentIndex.value == 2;
                            final total = controller.totalQuests;
                            final done = controller.completedCount;

                            return ProfileHeaderCard(
                              heroTag: isTabActive
                                  ? 'hero_profile_header'
                                  : 'hero_profile_header_tab_2',
                              gradientColors: const [
                                Color(0xFF845EF7),
                                Color(0xFF6C3CE1),
                              ],
                              // subtitle: 'my_quest'.tr,
                              trailing: total > 0
                                  ? SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Track
                                          const SizedBox(
                                            width: 56,
                                            height: 56,
                                            child: CircularProgressIndicator(
                                              value: 1.0,
                                              strokeWidth: 5,
                                              color: Colors.white24,
                                              strokeCap: StrokeCap.round,
                                            ),
                                          ),
                                          // Fill
                                          SizedBox(
                                            width: 56,
                                            height: 56,
                                            child: CircularProgressIndicator(
                                              value: total > 0 ? done / total : 0.0,
                                              strokeWidth: 5,
                                              color: Colors.white,
                                              backgroundColor: Colors.transparent,
                                              strokeCap: StrokeCap.round,
                                            ),
                                          ),
                                          // Label
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '$done/$total',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  height: 1.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  : null,
                            );
                          }),
                        ),
                        SizedBox(height: 10),
                        Expanded(
                          child: Obx(() {
                            if (controller.quests.isEmpty) {
                              return _buildEmptyState();
                            }

                            return _buildQuestList();
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Quest list with header ──────────────────────────────────────
  Widget _buildQuestList() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshQuests,
            color: const Color(0xFF845EF7),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                ...controller.quests.map(
                  (q) => QuestCard(
                    quest: q,
                    onStart: q.isCompleted
                        ? null
                        : () => controller.startQuest(q.id),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Empty state ─────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final bottomPadding = 80.0 + Get.mediaQuery.padding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF845EF7).withValues(alpha: 0.15),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF845EF7).withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.explore_rounded,
                      size: 46,
                      color: Color(0xFF845EF7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'no_quests_available'.tr,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2E2E4B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'complete_lessons_unlock_quests'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D5D78),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedButton(
                    onTap: () => controller.refreshQuests(),
                    icon: Icons.refresh_rounded,
                    label: 'refresh'.tr,
                    color: const Color(0xFF845EF7),
                    isLoading: controller.isLoading.value,
                    loaderIcon: null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
