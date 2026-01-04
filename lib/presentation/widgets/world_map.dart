import 'dart:ui';
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
  late ScrollController _scrollController;

  static const double _originalMapWidth = 440.0;
  static const double _originalMapHeight = 1325.0;

  final List<Map<String, double>> _levelPositions = [
    {'x': 269, 'y': 1266},
    {'x': 199, 'y': 1164},
    {'x': 134, 'y': 1048},
    {'x': 83, 'y': 921},
    {'x': 144, 'y': 812},
    {'x': 263, 'y': 787},
    {'x': 360, 'y': 728},
    {'x': 273, 'y': 647},
    {'x': 187, 'y': 594},
    {'x': 284, 'y': 499},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      setState(() {});
    });
    _scrollToCurrentLevel();
  }

  void _scrollToCurrentLevel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final levels = widget.world.levels;
      final targetIndex = _findCurrentLevelIndex(levels);

      final screenWidth = MediaQuery.of(context).size.width;
      final scaleFactor = screenWidth / _originalMapWidth;

      final targetY = _levelPositions[targetIndex]['y']! * scaleFactor;
      final targetPosition = targetY - (MediaQuery.of(context).size.height / 2);

      _scrollController.animateTo(
        targetPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
      );
    });
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / _originalMapWidth;
    final scaledMapHeight = _originalMapHeight * scaleFactor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade100, Colors.green.shade100],
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          width: screenWidth,
          height: scaledMapHeight,
          child: Stack(
            children: [
              _buildMapBackground(scaledMapHeight, screenWidth),
              _buildLevels(scaleFactor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapBackground(double height, double width) {
    return Image.asset(
      "assets/images/backgrounds/map_background.png",
      width: width,
      height: height,
      fit: BoxFit.fitWidth,
      errorBuilder: (_, __, ___) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.landscape, size: 120, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildLevels(double scaleFactor) {
    final levels = widget.world.levels;
    final currentIdx = _findCurrentLevelIndex(levels);

    const double baseSize = 74.0;
    const double halfSize = baseSize / 2;

    final double scrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;

    final double viewportH = MediaQuery.of(context).size.height;

    final double maxScroll = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;

    final double t = maxScroll <= 0
        ? 0.0
        : (scrollOffset / maxScroll).clamp(0.0, 1.0);

    // Focus line moves with scroll:
    // - when at top => focus near top (25% of screen)
    // - when at bottom => focus near bottom (75% of screen)
    final double focusFrac = lerpDouble(0.35, 1, t)!;
    final double focusY = viewportH * focusFrac;

    // Scaling behavior
    const double minScale = 0.4; // was 0.45
    const double maxScale = 1.00;
    final double falloff = viewportH * 0.75; // was 0.85 (too wide)

    return Stack(
      children: [
        for (int i = 0; i < levels.length && i < _levelPositions.length; i++)
          Builder(
            builder: (context) {
              final double rawX = _levelPositions[i]['x']! * scaleFactor;
              final double rawY = _levelPositions[i]['y']! * scaleFactor;

              // Where the level currently is inside the viewport
              final double yInView = rawY - scrollOffset;

              // Distance from moving focus line
              final double d = (yInView - focusY).abs();

              // Normalize 0..1 (0 = at focus, 1 = far)
              final double n = (d / falloff).clamp(0.0, 1.0);

              // Non-linear falloff feels nicer than linear
              // (keeps things bigger near focus, shrinks faster near edges)
              final double eased =
                  n * n; // you can try n*n*n for stronger falloff

              final double perspectiveScale =
                  (maxScale - (maxScale - minScale) * eased).clamp(
                    minScale,
                    maxScale,
                  );

              return Positioned(
                left: rawX - halfSize,
                top: rawY - halfSize,
                child: Transform.scale(
                  scale: perspectiveScale,
                  alignment: Alignment.center,
                  child: LevelCircle(
                    level: levels[i],
                    isCurrent: i == currentIdx,
                    onTap: _onLevelTap,
                  ),
                ),
              );
            },
          ),
      ],
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
    final double progress = (level.completionPercentage / 100.0).clamp(
      0.0,
      1.0,
    );
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
                              Icon(
                                Icons.play_arrow_rounded,
                                size: 18,
                                color: Colors.green.shade600,
                              )
                            else if (isCompleted)
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.orange.shade600,
                              ),
                          ],
                        )
                      : const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
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
    final borderColor = isCurrent
        ? Colors.yellow.shade700
        : Colors.black.withValues(alpha: 0.10);

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
