import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';
import 'package:mobilepenpal/data/controllers/adventure/adventure_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class AdventurePage extends StatefulWidget {
  AdventurePage({super.key});

  @override
  State<AdventurePage> createState() => _AdventurePageState();
}

class _AdventurePageState extends State<AdventurePage>
    with TickerProviderStateMixin {
  final AdventureController controller = Get.find<AdventureController>();
  late final ScrollController _scrollController;
  late final AnimationController _bounceCtrl;

  static const double _tileOriginalWidth = 440.0;
  static const double _tileOriginalHeight = 956.0;

  static const List<String> _bgTiles = [
    "assets/images/backgrounds/map_background_1.png",
    "assets/images/backgrounds/map_background_2.png",
    "assets/images/backgrounds/map_background_3.png",
    "assets/images/backgrounds/map_background_4.png",
  ];

  static const double _stageSpacing = 220.0;
  static const double _bottomInset = 150.0;
  static const double _topInset = 200.0;
  static const double _bubbleSize = 72.0;

  /// Category color map
  static const Map<String, Color> _categoryColors = {
    'consonants': Color(0xFF2B7A78),
    'dependent_vowels': Color(0xFF6C63FF),
    'independent_vowels': Color(0xFFE84393),
    'digits': Color(0xFFF39C12),
    'math': Color(0xFFE74C3C),
  };

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double _scaleFactor(double screenWidth) => screenWidth / _tileOriginalWidth;
  double _tileHeight(double screenWidth) =>
      _tileOriginalHeight * _scaleFactor(screenWidth);

  double _scaled(double designValue, double screenWidth) =>
      designValue * _scaleFactor(screenWidth);

  double _requiredContentHeight({
    required int stageCount,
    required double screenWidth,
  }) {
    final tileH = _tileHeight(screenWidth);
    if (stageCount <= 0) return tileH;

    final spacing = _scaled(_stageSpacing, screenWidth);
    final bottomInset = _scaled(_bottomInset, screenWidth);
    final topInset = _scaled(_topInset, screenWidth);

    return bottomInset + topInset + (stageCount - 1) * spacing;
  }

  double _stageCenterY({
    required int stageIndex,
    required double contentHeight,
    required double bottomInset,
    required double spacing,
  }) {
    return contentHeight - bottomInset - (stageIndex * spacing);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _onStageTap(AdventureStage stage) async {
    controller.isTransitioning.value = true;

    // Simulate/Allow for preparation time as requested
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      await Get.toNamed(
        AppRoutes.adventureStage,
        arguments: {
          'categoryLabel': stage.label,
          'exercises': stage.exercises,
        },
      );
    } finally {
      controller.isTransitioning.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      if (controller.stages.isEmpty) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.explore_off_rounded,
                  size: 60,
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No exercises available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGray60,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => controller.refreshExercises(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        body: LoadingOverlay(
          isLoading: controller.isTransitioning.value,
          child: _buildMap(context),
        ),
      );
    });
  }

  Widget _buildMap(BuildContext context) {
    final stages = controller.stages;
    final screenW = MediaQuery.of(context).size.width;
    final tileH = _tileHeight(screenW);

    final neededH = _requiredContentHeight(
      stageCount: stages.length,
      screenWidth: screenW,
    );

    final viewportH = MediaQuery.of(context).size.height;
    final contentH = max(neededH, viewportH);

    final tileCount = max(1, (contentH / tileH).ceil());

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      child: SizedBox(
        width: screenW,
        height: contentH,
        child: Stack(
          children: [
            _buildTiledBackground(
              width: screenW,
              tileHeight: tileH,
              tileCount: tileCount,
              contentHeight: contentH,
            ),
            _buildStageNodes(
              stages: stages,
              width: screenW,
              contentHeight: contentH,
              screenWidth: screenW,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiledBackground({
    required double width,
    required double tileHeight,
    required int tileCount,
    required double contentHeight,
  }) {
    if (tileCount <= 1) {
      return Positioned.fill(
        child: _bgTiles.isEmpty
            ? Container(color: Colors.grey.shade200)
            : Image.asset(
                _bgTiles.first,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
      );
    }

    return Stack(
      children: List.generate(tileCount, (i) {
        final a = _bgTiles[i % _bgTiles.length];

        return Positioned(
          left: 0,
          right: 0,
          bottom: i * tileHeight,
          height: tileHeight,
          child: Image.asset(
            a,
            width: width,
            height: tileHeight,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, __, ___) =>
                Container(color: Colors.grey.shade200),
          ),
        );
      }),
    );
  }

  Widget _buildStageNodes({
    required List<AdventureStage> stages,
    required double width,
    required double contentHeight,
    required double screenWidth,
  }) {
    if (stages.isEmpty) return const SizedBox();

    final spacing = _scaled(_stageSpacing, screenWidth);
    final bottomInset = _scaled(_bottomInset, screenWidth);

    final centerX = width * 0.5;
    final left = centerX - (_bubbleSize / 2);

    return Stack(
      children: List.generate(stages.length, (i) {
        final y = _stageCenterY(
          stageIndex: i,
          contentHeight: contentHeight,
          bottomInset: bottomInset,
          spacing: spacing,
        );

        return Positioned(
          left: left,
          top: y - (_bubbleSize / 2),
          child: _AdventureStageCircle(
            stage: stages[i],
            bounce: _bounceCtrl,
            bounceHeight: 8.0,
            isCurrent: i == 0,
            onTap: _onStageTap,
          ),
        );
      }),
    );
  }
}

class _AdventureStageCircle extends StatelessWidget {
  final AdventureStage stage;
  final Animation<double> bounce;
  final double bounceHeight;
  final bool isCurrent;
  final Function(AdventureStage) onTap;

  const _AdventureStageCircle({
    required this.stage,
    required this.bounce,
    required this.bounceHeight,
    required this.isCurrent,
    required this.onTap,
  });

  Color get _stageColor =>
      _AdventurePageState._categoryColors[stage.categoryType] ??
      AppColors.primary;

  @override
  Widget build(BuildContext context) {
    const double ring = 72;

    Widget body = SizedBox(
      width: ring,
      height: ring,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Title pill above the circle
          Positioned(
            top: -52,
            child: _StageTitlePill(
              text: stage.label,
              subtitle: '${stage.exercises.length} exercises',
              color: _stageColor,
            ),
          ),

          // Glow halo for current stage
          if (isCurrent) _GlowHalo(size: 90, color: _stageColor),

          // Circle button
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: Ink(
              width: ring,
              height: ring,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onTap(stage),
                child: Container(
                  width: ring,
                  height: ring,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.92),
                    border: Border.all(
                      color: _stageColor,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _stageColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${stage.index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        height: 1.0,
                        color: _stageColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!isCurrent) return body;

    return AnimatedBuilder(
      animation: bounce,
      builder: (context, child) {
        final dy = -bounceHeight * bounce.value;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: body,
    );
  }
}

class _StageTitlePill extends StatelessWidget {
  final String text;
  final String subtitle;
  final Color color;

  const _StageTitlePill({
    required this.text,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowHalo extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowHalo({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
