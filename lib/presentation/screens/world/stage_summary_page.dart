import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/data/controllers/world/stage_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';

class StageSummaryPage extends StatefulWidget {
  const StageSummaryPage({super.key});

  @override
  State<StageSummaryPage> createState() => _StageSummaryPageState();
}

class _StageSummaryPageState extends State<StageSummaryPage>
    with TickerProviderStateMixin {
  late final int worldId;
  late final int levelId;
  late final int stageId;

  static const int maxStars = 3;
  late final int starsEarned;
  late final int correctAnswers;
  late final int totalQuestions;
  late final int? nextStageId;

  late final List<AnimationController> _starControllers;

  bool _isContinuing = false;

  @override
  void initState() {
    super.initState();

    final params = Get.parameters;
    worldId = int.tryParse(params['worldId'] ?? '0') ?? 0;
    levelId = int.tryParse(params['levelId'] ?? '0') ?? 0;
    stageId = int.tryParse(params['stageId'] ?? '0') ?? 0;

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final summary = args['summary'] as Map<String, dynamic>? ?? {};

    starsEarned = (summary['stars_earned'] as int?) ?? 0;
    correctAnswers = (summary['correct_answers'] as int?) ?? 0;
    totalQuestions = (summary['total_questions'] as int?) ?? 0;

    final dynamic rawNextStageId = summary['next_stage_id'];

    if (rawNextStageId is int) {
      nextStageId = rawNextStageId;
    } else if (rawNextStageId is String) {
      nextStageId = int.tryParse(rawNextStageId);
    } else {
      nextStageId = null;
    }

    _starControllers = List.generate(
      maxStars,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStarAnimations();
    });
  }

  @override
  void dispose() {
    for (final c in _starControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _startStarAnimations() async {
    if (starsEarned <= 0) return;

    await Future.delayed(const Duration(milliseconds: 400));

    for (var i = 0; i < starsEarned && i < maxStars; i++) {
      final controller = _starControllers[i];
      controller.reset();
      controller.forward();
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isContinuing, // 👈 show overlay while continuing
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2B7A78), Color(0xFF6B9F8E), Color(0xFF8FB99F)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildTopBar(),
                const SizedBox(height: 24),
                _buildIcon(),
                const SizedBox(height: 24),
                _buildScore(),
                Expanded(child: _buildStarDisplay()),
                _buildBottomButtons(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            final levelRoute = RouteBuilder.build(AppRoutes.level, {
              'worldId': worldId.toString(),
              'levelId': levelId.toString(),
            });
            Get.offNamed(levelRoute);
          },
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Lottie.asset("assets/animated/trophy.json", repeat: false),
    );
  }

  Widget _buildScore() {
    return Column(
      children: [
        Text(
          '$correctAnswers/$totalQuestions',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'ចម្លើយត្រឹមត្រូវ',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStarDisplay() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(maxStars, (index) {
          final isEarned = index < starsEarned;
          double dy;
          if (index == 1) {
            dy = -18;
          } else {
            dy = 6;
          }

          return Transform.translate(
            offset: Offset(0, dy),
            child: SizedBox(
              width: 120,
              height: 120,
              child: Lottie.asset(
                isEarned
                    ? 'assets/animated/star.json'
                    : 'assets/animated/star_border.json',
                controller: isEarned ? _starControllers[index] : null,
                onLoaded: isEarned
                    ? (composition) {
                        _starControllers[index].duration = composition.duration;
                      }
                    : null,
                repeat: false,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                try {
                  final stageController = Get.find<StageController>();
                  stageController.resetForRetry();
                } catch (_) {}

                final stageRoute = RouteBuilder.build(AppRoutes.stage, {
                  'worldId': worldId.toString(),
                  'levelId': levelId.toString(),
                  'stageId': stageId.toString(),
                });

                Get.offNamed(stageRoute);
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1FB9FF),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'retry'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (nextStageId != null) {
                  setState(() {
                    _isContinuing = true;
                  });

                  try {
                    final stageController = Get.find<StageController>();
                    await stageController.loadStage(
                      newStageId: nextStageId!,
                      newWorldId: worldId,
                      newLevelId: levelId,
                    );
                  } catch (_) {}

                  if (!mounted) return;

                  final nextStageRoute = RouteBuilder.build(AppRoutes.stage, {
                    'worldId': worldId.toString(),
                    'levelId': levelId.toString(),
                    'stageId': nextStageId.toString(),
                  });

                  Get.offNamed(nextStageRoute);
                } else {
                  final levelRoute = RouteBuilder.build(AppRoutes.level, {
                    'worldId': worldId.toString(),
                    'levelId': levelId.toString(),
                  });
                  Get.offNamed(levelRoute);
                }
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'continue'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
