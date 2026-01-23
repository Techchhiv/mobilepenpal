import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/data/controllers/world/level_controller.dart';
import 'package:mobilepenpal/data/models/world/world.dart';
import 'package:mobilepenpal/data/models/world/world_level.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class WorldMap extends StatefulWidget {
  final World world;

  const WorldMap({super.key, required this.world});

  @override
  State<WorldMap> createState() => _WorldMapState();
}

class _WorldMapState extends State<WorldMap> {
  late final ScrollController _scrollController;

  static const double _tileOriginalWidth = 440.0;
  static const double _tileOriginalHeight = 1325.0;

  static const List<String> _bgTiles = [
    "assets/images/backgrounds/map_background.png",
    // "assets/images/backgrounds/map_background_2.png",
    // "assets/images/backgrounds/map_background_3.png",
    // "assets/images/backgrounds/map_background_4.png",
    // "assets/images/backgrounds/map_background_5.png",
  ];

  /// Ensure user can scroll even if few levels.
  static const int _minTiles = 1;

  /// Distance between each level center
  static const double _levelSpacingDesign = 240.0;

  /// How far Level 1 center is from the very bottom of the scroll content.
  static const double _bottomInsetDesign = 150.0;

  /// Extra padding at the very top so last level isn't glued to edge.
  static const double _topInsetDesign = 260.0;

  /// LevelCircle size approximation for centering.
  static const double _bubbleSize = 72.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentLevel());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  double _scaleFactor(double screenWidth) => screenWidth / _tileOriginalWidth;
  double _tileHeight(double screenWidth) =>
      _tileOriginalHeight * _scaleFactor(screenWidth);

  double _scaled(double designValue, double screenWidth) =>
      designValue * _scaleFactor(screenWidth);

  double _requiredContentHeight({
    required int levelCount,
    required double screenWidth,
  }) {
    final tileH = _tileHeight(screenWidth);
    if (levelCount <= 0) return tileH;

    final spacing = _scaled(_levelSpacingDesign, screenWidth);
    final bottomInset = _scaled(_bottomInsetDesign, screenWidth);
    final topInset = _scaled(_topInsetDesign, screenWidth);

    return bottomInset + topInset + (levelCount - 1) * spacing;
  }

  int _tileCountForHeight({
    required double contentHeight,
    required double tileHeight,
  }) {
    return max(_minTiles, (contentHeight / tileHeight).ceil());
  }

  int _findCurrentLevelIndex(List<WorldLevel> levels) {
    for (int i = 0; i < levels.length; i++) {
      final level = levels[i];
      final bool isCompleted = level.completionPercentage >= 100;
      final bool isUnlocked = level.isUnlocked == 1 || level.isUnlocked == true;

      if (isUnlocked && !isCompleted) return i;
    }
    return levels.isEmpty ? 0 : levels.length - 1;
  }

  double _levelCenterY({
    required int levelIndex,
    required double contentHeight,
    required double bottomInset,
    required double spacing,
  }) {
    return contentHeight - bottomInset - (levelIndex * spacing);
  }

  void _scrollToCurrentLevel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final levels = widget.world.levels;
      if (levels.isEmpty) return;

      final screenW = MediaQuery.of(context).size.width;
      final tileH = _tileHeight(screenW);

      final neededH =
          _requiredContentHeight(levelCount: levels.length, screenWidth: screenW);
      final tileCount = _tileCountForHeight(contentHeight: neededH, tileHeight: tileH);

      final contentH = tileCount * tileH;

      final spacing = _scaled(_levelSpacingDesign, screenW);
      final bottomInset = _scaled(_bottomInsetDesign, screenW);

      final idx = _findCurrentLevelIndex(levels);
      final targetY = _levelCenterY(
        levelIndex: idx,
        contentHeight: contentH,
        bottomInset: bottomInset,
        spacing: spacing,
      );

      final viewportH = MediaQuery.of(context).size.height;
      final targetOffset = (targetY - viewportH * 0.55)
          .clamp(0.0, _scrollController.position.maxScrollExtent);

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _onLevelTap(WorldLevel level) async {
    final bool isUnlocked = level.isUnlocked == 1 || level.isUnlocked == true;

    if (!isUnlocked) {
      _showSnackBar('This level is locked 🔒', Colors.orange);
      return;
    }

    final levelController = Get.find<LevelController>();
    levelController.worldId = widget.world.id;
    levelController.levelId = level.id;

    await levelController.fetchLevelDetail();

    final currentLevel = levelController.currentLevel.value;
    if (currentLevel == null || currentLevel.id != level.id) {
      _showSnackBar('Failed to load level', Colors.red);
      return;
    }

    final route = RouteBuilder.build(AppRoutes.level, {
      'worldId': widget.world.id.toString(),
      'levelId': level.id.toString(),
    });

    await Future.delayed(Duration.zero);
    Get.toNamed(route);
  }

  void _showSnackBar(String message, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bg,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levels = widget.world.levels;

    final screenW = MediaQuery.of(context).size.width;
    final tileH = _tileHeight(screenW);

    final neededH =
        _requiredContentHeight(levelCount: levels.length, screenWidth: screenW);
    final tileCount = _tileCountForHeight(contentHeight: neededH, tileHeight: tileH);

    final contentH = tileCount * tileH;

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
            ),
            _buildLevelsContinuous(
              levels: levels,
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
  }) {
    return Stack(
      children: List.generate(tileCount, (i) {
        final asset = _bgTiles.isEmpty ? null : _bgTiles[i % _bgTiles.length];

        return Positioned(
          left: 0,
          right: 0,
          top: i * tileHeight,
          height: tileHeight,
          child: asset == null
              ? Container(color: Colors.grey.shade200)
              : Image.asset(
                  asset,
                  width: width,
                  height: tileHeight,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.landscape, size: 120, color: Colors.grey),
                    ),
                  ),
                ),
        );
      }),
    );
  }

  Widget _buildLevelsContinuous({
    required List<WorldLevel> levels,
    required double width,
    required double contentHeight,
    required double screenWidth,
  }) {
    if (levels.isEmpty) return const SizedBox();

    final currentIdx = _findCurrentLevelIndex(levels);

    final spacing = _scaled(_levelSpacingDesign, screenWidth);
    final bottomInset = _scaled(_bottomInsetDesign, screenWidth);

    final centerX = width * 0.5;
    final left = centerX - (_bubbleSize / 2);

    return Stack(
      children: List.generate(levels.length, (i) {
        final y = _levelCenterY(
          levelIndex: i,
          contentHeight: contentHeight,
          bottomInset: bottomInset,
          spacing: spacing,
        );

        return Positioned(
          left: left,
          top: y - (_bubbleSize / 2),
          child: LevelCircle(
            level: levels[i],
            isCurrent: i == currentIdx,
            onTap: _onLevelTap,
          ),
        );
      }),
    );
  }
}

class LevelCircle extends StatelessWidget {
  final WorldLevel level;
  final bool isCurrent;
  final Function(WorldLevel) onTap;

  const LevelCircle({
    super.key,
    required this.level,
    required this.onTap,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnlocked = level.isUnlocked == 1 || level.isUnlocked == true;
    final double progress = (level.completionPercentage / 100.0).clamp(0.0, 1.0);
    final bool isCompleted = progress >= 1.0;

    const double ring = 72;
    const double core = 56;
    const double halo = 86;

    final Color progressColor = Colors.blue.shade600;

    return SizedBox(
      width: ring,
      height: ring,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -52,
            child: _FloatingCard(
              text: level.name,
              isCurrent: isCurrent,
              isUnlocked: isUnlocked,
            ),
          ),
          if (isCurrent && isUnlocked) _CleanHalo(size: halo),
          SizedBox(
            width: ring,
            height: ring,
            child: CircularProgressIndicator(
              value: isUnlocked ? progress : 0.0,
              strokeWidth: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.85),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: Ink(
              width: core,
              height: core,
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.white : Colors.grey.shade400,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade600, width: 3),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onTap(level),
                child: Center(
                  child: isUnlocked
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${level.orderIndex}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                height: 1.0,
                                color: Colors.black,
                              ),
                            ),
                            if (isCurrent && !isCompleted)
                              Icon(Icons.play_arrow_rounded,
                                  size: 18, color: Colors.green.shade600)
                            else if (isCompleted)
                              Icon(Icons.star,
                                  size: 16, color: Colors.orange.shade600),
                          ],
                        )
                      : const Icon(Icons.lock_rounded,
                          color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
          if (isCompleted)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _CleanHalo extends StatelessWidget {
  final double size;
  const _CleanHalo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withValues(alpha: 0.35),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.yellow.shade400, width: 4),
          ),
        ),
      ],
    );
  }
}

class _FloatingCard extends StatelessWidget {
  final String text;
  final bool isCurrent;
  final bool isUnlocked;

  const _FloatingCard({
    required this.text,
    required this.isCurrent,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Colors.white;
    final borderColor =
        isCurrent ? Colors.yellow.shade700 : Colors.black.withValues(alpha: 0.10);

    final fg = isUnlocked ? Colors.black : Colors.black.withValues(alpha: 0.65);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(18, 10),
          painter: _TrianglePainter(color: bg),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
