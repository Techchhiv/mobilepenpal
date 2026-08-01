import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/core/localization/locale_controller.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/data/controllers/world/level_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/models/level/level_stage.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';
import 'package:mobilepenpal/data/controllers/world/heart_controller.dart';
import 'package:mobilepenpal/presentation/widgets/world/out_of_hearts_modal.dart';
import 'package:mobilepenpal/presentation/widgets/world/heart_status_widget.dart';
import 'package:mobilepenpal/presentation/widgets/world/heart_deduct_overlay.dart';

class LevelDetailPage extends StatefulWidget {
  const LevelDetailPage({super.key});

  @override
  State<LevelDetailPage> createState() => _LevelDetailPageState();
}

class _LevelDetailPageState extends State<LevelDetailPage> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<LevelController>();
    _currentIndex = controller.initialStageIndex.value;
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.78,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LevelController>();

    return Scaffold(
      body: Obx(() {
        final level = controller.currentLevel.value;

        return LoadingOverlay(
          isLoading: controller.isLoading.value,
          child: Stack(
            children: [
              // Full Screen Theme Background
              Positioned.fill(
                child: Image.asset(
                  'assets/images/backgrounds/background_level_practice.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/backgrounds/level_background.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Foreground Content
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(controller),
                    Expanded(
                      child: level == null
                          ? _buildNotFound(controller)
                          : _buildStageContent(level.stages),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTopBar(LevelController controller) {
    final lc = Get.find<LocaleController>();

    return GetBuilder<LocaleController>(
      builder: (_) {
        final level = controller.currentLevel.value;
        final worldTitle = lc.isKhmer
            ? (level?.worldName ?? 'Loading...')
            : (level?.worldNameEn ?? level?.worldName ?? 'Loading...');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  final canPop = Get.key.currentState?.canPop() == true;
                  if (canPop) {
                    Get.back();
                  } else if (controller.worldId > 0) {
                    final worldRoute = RouteBuilder.build(AppRoutes.world, {
                      'id': controller.worldId.toString(),
                    });
                    Get.offNamed(worldRoute);
                  } else {
                    Get.offNamed(AppRoutes.home);
                  }
                },
              ),
              Expanded(
                child: Text(
                  worldTitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const HeartStatusWidget(compact: true),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () async {
                  controller.isLoading.value = true;
                  try {
                    final homeController = Get.find<HomeController>();
                    await homeController.fetchStudentProfile();
                  } finally {
                    controller.isLoading.value = false;
                    Get.offAllNamed(AppRoutes.home);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotFound(LevelController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          Text(
            'level_not_found'.tr,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => controller.fetchLevelDetail(),
            child: Text('retry'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildStageContent(List<LevelStage> stages) {
    if (stages.isEmpty) return const SizedBox.shrink();

    if (_currentIndex >= stages.length) {
      _currentIndex = 0;
    }

    return Column(
      children: [
        // Swipable Stage Viewer with Peeking Side Cards
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: stages.length,
            onPageChanged: (idx) {
              setState(() {
                _currentIndex = idx;
              });
            },
            itemBuilder: (context, index) {
              final stage = stages[index];

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page! - index).abs();
                    value = (1 - (value * 0.12)).clamp(0.88, 1.0);
                  } else {
                    value = index == _currentIndex ? 1.0 : 0.88;
                  }

                  return Transform.scale(scale: value, child: child);
                },
                child: _buildStageView(stage, index + 1, stages.length),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStageView(LevelStage stage, int stageNumber, int totalStages) {
    final lc = Get.find<LocaleController>();
    final isUnlocked =
        stage.status == 'unlocked' || stage.status == 'completed';

    String cardTitle;
    if (lc.isKhmer) {
      if (stage.name.contains('រៀន') ||
          stage.name.contains('សរសេរ') ||
          stage.name.contains('ហាត់')) {
        cardTitle = stage.name;
      } else {
        cardTitle = 'រៀនសរសេរ  ${stage.name}';
      }
    } else {
      final nameEn = stage.nameEn?.trim() ?? '';
      if (nameEn.toLowerCase().startsWith('practice') ||
          nameEn.toLowerCase().startsWith('learn')) {
        cardTitle = nameEn;
      } else {
        cardTitle = 'Practice letter $nameEn';
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Top empty space pushing bottom card down
          Column(
            children: [
              const Spacer(),

              // Bottom White Card Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 24,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Stage Progress Badge (1/5)
                    Text(
                      NumberFormatUtils.fraction(stageNumber, totalStages),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Card Title & Stars (vertically aligned together)
                    Container(
                      padding: const EdgeInsets.only(left: 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            cardTitle,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildStarDisplay(stage.starsEarned, 3),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Start Action Button (Teal Pill Button)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isUnlocked
                            ? () => _navigateToStage(stage.id)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isUnlocked
                              ? const Color(0xFF0C7365)
                              : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: isUnlocked ? 6 : 0,
                          shadowColor: const Color(
                            0xFF0C7365,
                          ).withValues(alpha: 0.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isUnlocked
                                  ? Icons.play_arrow_rounded
                                  : Icons.lock_rounded,
                              size: 24,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isUnlocked ? 'start'.tr : 'locked'.tr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Animated Kid Character at the VERY START (far left edge)
          Positioned(
            left: -70,
            bottom: 115,
            child: TweenAnimationBuilder<double>(
              key: ValueKey('kid_$stageNumber'),
              tween: Tween(begin: 0.3, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  alignment: Alignment.bottomLeft,
                  child: Image.asset(
                    'assets/images/illustrations/kid_character.png',
                    width: 295,
                    height: 295,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarDisplay(int starsEarned, int maxStars) {
    const fixedMax = 3;
    final earned = starsEarned.clamp(0, fixedMax);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: List.generate(fixedMax, (index) {
        final isFilled = index < earned;
        return Padding(
          padding: const EdgeInsets.only(left: 0.0),
          child: Lottie.asset(
            isFilled
                ? 'assets/animated/star.json'
                : 'assets/animated/star_border.json',
            repeat: false,
            animate: isFilled,
            width: 40,
            height: 40,
            fit: BoxFit.contain,
          ),
        );
      }),
    );
  }

  Future<void> _navigateToStage(int stageId) async {
    final heartController = Get.isRegistered<HeartController>()
        ? HeartController.to
        : Get.put(HeartController());

    if (!heartController.isUnlimited.value && heartController.currentHearts.value <= 0) {
      Get.dialog(const OutOfHeartsModal());
      return;
    }

    final controller = Get.find<LevelController>();
    final stageController = Get.find<StageController>();

    // Start Parallel Execution: Heart deduct animation (~700ms) + Stage data loading
    final isFreeTier = !heartController.isUnlimited.value;
    final animationFuture = isFreeTier
        ? HeartDeductOverlay.show(context)
        : Future.value();

    bool isDataLoaded = false;
    final loadFuture = stageController.loadStage(
      newStageId: stageId,
      newWorldId: controller.worldId,
      newLevelId: controller.levelId,
    ).then((_) {
      isDataLoaded = true;
    });

    try {
      // 1. Wait for animation to complete first
      await animationFuture;

      // 2. If data loading is still in progress, display loading overlay until finished
      if (!isDataLoaded) {
        controller.isLoading.value = true;
      }
      await loadFuture;

      if (stageController.currentStage.value == null) {
        AppSnackbar.show(
          title: 'error'.tr,
          'stage_not_found'.tr,
          backgroundColor: Colors.red,
        );
        return;
      }

      final canPlay = await heartController.useHeart();
      if (!canPlay) {
        Get.dialog(const OutOfHeartsModal());
        return;
      }

      final route = RouteBuilder.build(AppRoutes.stage, {
        'worldId': controller.worldId.toString(),
        'levelId': controller.levelId.toString(),
        'stageId': stageId.toString(),
      });

      controller.isLoading.value = false;
      await Future.delayed(Duration.zero);

      Get.toNamed(route);
    } finally {
      controller.isLoading.value = false;
    }
  }
}
