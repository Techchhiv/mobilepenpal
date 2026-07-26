import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/data/controllers/world/level_controller.dart';
import 'package:mobilepenpal/data/controllers/world/world_controller.dart';
import 'package:mobilepenpal/data/models/world/world.dart';
import 'package:mobilepenpal/data/models/world/world_level.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/home/subscribe_modal.dart';

class WorldMap extends StatefulWidget {
  final World world;

  const WorldMap({super.key, required this.world});

  @override
  State<WorldMap> createState() => _WorldMapState();
}

class _WorldMapState extends State<WorldMap> with TickerProviderStateMixin {
  late final ScrollController _scrollController;

  static const double _mapOriginalWidth = 832.0;
  static const double _mapOriginalHeight = 5088.0;

  static const String _mapBgAsset =
      "assets/images/backgrounds/map_background_test.png";
  // ignore: unused_field
  static const String _floorAsset =
      "assets/images/backgrounds/map_background_floor.png";

  /// Predefined waypoints (leftRatio, bottomRatio) relative to map background width and height
  static const List<Offset> _designWaypoints = [
    Offset(0.56, 0.042),
    Offset(0.38, 0.076),
    Offset(0.58, 0.158),
    Offset(0.55, 0.218),
    Offset(0.34, 0.275),
    Offset(0.525, 0.318),
    Offset(0.45, 0.385),
    Offset(0.32, 0.440),
    Offset(0.55, 0.500),
    Offset(0.62, 0.560),
    Offset(0.36, 0.620),
    Offset(0.54, 0.680),
    Offset(0.40, 0.740),
    Offset(0.58, 0.800),
    Offset(0.35, 0.860),
    Offset(0.50, 0.920),
  ];

  Offset _getWaypoint(int index) {
    if (index < _designWaypoints.length) {
      return _designWaypoints[index];
    }
    final last = _designWaypoints.last;
    final extra = index - _designWaypoints.length + 1;
    final bottom = last.dy + (extra * 0.05);
    final left = 0.45 + 0.15 * sin(index * 1.2);
    return Offset(left, bottom);
  }

  /// Cap scaling so tablets don't get oversized spacing / zoomed background.
  static const double _maxScaleWidth = 500.0;

  late final AnimationController waveCtrl;
  late final AnimationController bounceCtrl;

  bool _waveActive = false;
  bool _bounceActive = false;

  bool _boolish(dynamic v) => v == true || v == 1 || v == '1';

  double _progress01(dynamic pct) {
    final n = (pct is num) ? pct.toDouble() : double.tryParse('$pct') ?? 0.0;
    return (n / 100.0).clamp(0.0, 1.0);
  }

  void _applyAnim({required bool wave, required bool bounce}) {
    if (wave != _waveActive) {
      _waveActive = wave;
      if (wave) {
        waveCtrl.repeat();
      } else {
        waveCtrl.stop();
        waveCtrl.value = 0;
      }
    }

    if (bounce != _bounceActive) {
      _bounceActive = bounce;
      if (bounce) {
        bounceCtrl.repeat(reverse: true);
      } else {
        bounceCtrl.stop();
        bounceCtrl.value = 0;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToCurrentLevel(),
    );
  }

  @override
  void dispose() {
    waveCtrl.dispose();
    bounceCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double _requiredContentHeight({
    required int levelCount,
    required double mapWidth,
    required double viewportHeight,
  }) {
    final fullBgHeight = mapWidth * (_mapOriginalHeight / _mapOriginalWidth);
    if (levelCount <= 0) return fullBgHeight;

    final lastWp = _getWaypoint(levelCount - 1);
    final highestLevelYFromBottom = fullBgHeight * lastWp.dy;
    final paddingAbove = max(1400, viewportHeight * 0.25);
    final maxScrollableH = highestLevelYFromBottom + paddingAbove;

    return min(fullBgHeight, maxScrollableH);
  }

  int _findCurrentLevelIndex(List<WorldLevel> levels) {
    for (int i = 0; i < levels.length; i++) {
      final level = levels[i];
      final bool isCompleted = _progress01(level.completionPercentage) >= 1.0;
      final bool isUnlocked = _boolish(level.isUnlocked);

      if (isUnlocked && !isCompleted) return i;
    }
    return levels.isEmpty ? 0 : levels.length - 1;
  }

  void _scrollToCurrentLevel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final levels = widget.world.levels;
      if (levels.isEmpty) return;

      final screenW = MediaQuery.of(context).size.width;
      final mapWidth = min(screenW, _maxScaleWidth);
      final viewportH = MediaQuery.of(context).size.height;
      final fullBgH = mapWidth * (_mapOriginalHeight / _mapOriginalWidth);

      final neededH = _requiredContentHeight(
        levelCount: levels.length,
        mapWidth: mapWidth,
        viewportHeight: viewportH,
      );

      final contentH = max(neededH, viewportH);

      final idx = _findCurrentLevelIndex(levels);
      final wp = _getWaypoint(idx);
      final targetY = contentH - (fullBgH * wp.dy);

      final targetOffset = (targetY - viewportH * 0.55).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _onLevelTap(WorldLevel level) async {
    if (level.isLockedBySubscription) {
      Get.dialog(const SubscribeModal());
      return;
    }

    final bool isUnlocked = _boolish(level.isUnlocked);

    if (!isUnlocked) {
      _showSnackBar('level_locked'.tr, Colors.orange);
      return;
    }

    final worldController = Get.find<WorldController>();
    final levelController = Get.find<LevelController>();
    levelController.worldId = widget.world.id;
    levelController.levelId = level.id;

    worldController.isNavigatingToLevel.value = true;
    try {
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

      Get.toNamed(route);
    } finally {
      worldController.isNavigatingToLevel.value = false;
    }
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
    final mapWidth = min(screenW, _maxScaleWidth);
    final viewportH = MediaQuery.of(context).size.height;
    final fullBgH = mapWidth * (_mapOriginalHeight / _mapOriginalWidth);

    final neededH = _requiredContentHeight(
      levelCount: levels.length,
      mapWidth: mapWidth,
      viewportHeight: viewportH,
    );

    final contentH = max(neededH, viewportH);

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      child: SizedBox(
        width: screenW,
        height: contentH,
        child: Stack(
          children: [
            // Background covers full screen width
            _buildMapBackground(width: screenW, contentHeight: contentH),
            // Game levels path stays centered in mapWidth
            Positioned(
              left: (screenW - mapWidth) / 2,
              top: 0,
              bottom: 0,
              width: mapWidth,
              child: _buildLevelsContinuous(
                levels: levels,
                width: mapWidth,
                contentHeight: contentH,
                fullBgHeight: fullBgH,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBackground({
    required double width,
    required double contentHeight,
  }) {
    return Positioned.fill(
      child: Image.asset(
        _mapBgAsset,
        width: width,
        height: contentHeight,
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
      ),
    );
  }

  Widget _buildLevelsContinuous({
    required List<WorldLevel> levels,
    required double width,
    required double contentHeight,
    required double fullBgHeight,
  }) {
    if (levels.isEmpty) return const SizedBox();

    bool isUnlockedOf(WorldLevel l) => _boolish(l.isUnlocked);
    double progress01Of(WorldLevel l) => _progress01(l.completionPercentage);

    final currentIdx = _findCurrentLevelIndex(levels);

    final currentLevel = levels[currentIdx];
    final currentUnlocked = isUnlockedOf(currentLevel);
    final currentCompleted = progress01Of(currentLevel) >= 1.0;
    final shouldBounceCurrent = currentUnlocked && !currentCompleted;

    final anyWave = levels.any((l) {
      final unlocked = isUnlockedOf(l);
      final completed = progress01Of(l) >= 1.0;
      return unlocked && !completed;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyAnim(wave: anyWave, bounce: shouldBounceCurrent);
    });

    return Stack(
      children: [
        for (int i = 0; i < levels.length; i++) ...[
          // Floor base image platform (commented out as map background image already has stone floors)
          /*
          const double floorWidth = 62.0;
          const double floorHeight = 52.0;

          Positioned(
            left: (width * _getWaypoint(i).dx) - (floorWidth / 2),
            top: contentHeight - (fullBgHeight * _getWaypoint(i).dy) - (floorHeight / 2) + 10.0,
            child: Image.asset(
              _floorAsset,
              width: floorWidth,
              height: floorHeight,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
          */
          // Level Circle node
          Positioned(
            left: (width * _getWaypoint(i).dx) - 40.0,
            top: contentHeight - (fullBgHeight * _getWaypoint(i).dy) - 75.0,
            child: LevelCircle(
              wave: waveCtrl,
              bounce: bounceCtrl,
              bounceHeight: 8.0,
              waveAmplitudeFactor: 0.06,
              waveAmplitudeMin: 2.0,
              waveWavelengthFactor: 0.95,
              level: levels[i],
              isCurrent: i == currentIdx,
              onTap: _onLevelTap,
            ),
          ),
        ],
      ],
    );
  }
}

class LevelCircle extends StatefulWidget {
  final Animation<double> wave;
  final Animation<double> bounce;
  final double bounceHeight;

  final double waveAmplitudeFactor;
  final double waveAmplitudeMin;
  final double waveWavelengthFactor;

  final WorldLevel level;
  final bool isCurrent;
  final Function(WorldLevel) onTap;

  const LevelCircle({
    super.key,
    required this.wave,
    required this.bounce,
    required this.bounceHeight,
    required this.waveAmplitudeFactor,
    required this.waveAmplitudeMin,
    required this.waveWavelengthFactor,
    required this.level,
    required this.onTap,
    required this.isCurrent,
  });

  @override
  State<LevelCircle> createState() => _LevelCircleState();
}

class _LevelCircleState extends State<LevelCircle> {
  bool _isPressed = false;

  bool get _isUnlocked => widget.level.isUnlocked;
  bool get _isSubLocked => widget.level.isLockedBySubscription == true;
  double get _progress =>
      ((widget.level.completionPercentage) / 100.0).clamp(0.0, 1.0);
  bool get _isCompleted => _progress >= 1.0;

  String _getThumbnailAsset(int orderIndex) {
    final idx = ((orderIndex - 1) % 7) + 1;
    if (idx == 2) {
      return 'assets/images/levels/pen2.jpeg';
    }
    return 'assets/images/levels/pen$idx.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = _isCompleted;
    final bool isSubLocked = _isSubLocked;
    final bool isUnlocked = _isUnlocked;
    final bool isCurrentActive = widget.isCurrent && isUnlocked && !isCompleted;

    final String title = widget.level.name.trim().isEmpty
        ? 'Level ${widget.level.orderIndex}'
        : widget.level.name.trim();

    final String thumbAsset = _getThumbnailAsset(widget.level.orderIndex);

    // Styling based on level state
    Color borderColor;
    List<BoxShadow> boxShadows;
    Gradient badgeGradient;

    if (isCurrentActive) {
      borderColor = const Color(0xFF22BAAF);
      badgeGradient = const LinearGradient(
        colors: [Color(0xFF149B95), Color(0xFF22BAAF)],
      );
      boxShadows = [
        BoxShadow(
          color: const Color(0xFF22BAAF).withValues(alpha: 0.6),
          blurRadius: 16,
          spreadRadius: 2,
        ),
        const BoxShadow(
          color: Colors.black45,
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ];
    } else if (isCompleted) {
      borderColor = const Color(0xFF22C55E);
      badgeGradient = const LinearGradient(
        colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
      );
      boxShadows = [
        BoxShadow(
          color: const Color(0xFF22C55E).withValues(alpha: 0.5),
          blurRadius: 12,
          spreadRadius: 1,
        ),
        const BoxShadow(
          color: Colors.black45,
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ];
    } else if (isSubLocked) {
      borderColor = const Color(0xFFFBBF24);
      badgeGradient = const LinearGradient(
        colors: [Color(0xFFD97706), Color(0xFFFBBF24)],
      );
      boxShadows = [
        const BoxShadow(
          color: Colors.black38,
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ];
    } else {
      borderColor = Colors.white.withValues(alpha: 0.6);
      badgeGradient = const LinearGradient(
        colors: [Color(0xFF4B5563), Color(0xFF6B7280)],
      );
      boxShadows = [
        const BoxShadow(
          color: Colors.black38,
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ];
    }

    return AnimatedBuilder(
      animation: widget.bounce,
      builder: (context, child) {
        final double floatOffsetY = isCurrentActive
            ? sin(widget.bounce.value * pi) * -6.0
            : 0.0;
        final double arrowOffsetY = isCurrentActive
            ? sin(widget.bounce.value * pi) * -5.0
            : 0.0;

        return Transform.translate(
          offset: Offset(0, floatOffsetY),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () => widget.onTap(widget.level),
            child: AnimatedScale(
              scale: _isPressed ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: 80,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // Floating arrow pointer for active level
                    if (isCurrentActive)
                      Positioned(
                        top: -24 + arrowOffsetY,
                        child: Text(
                          '▼',
                          style: TextStyle(
                            fontSize: 18,
                            color: const Color(0xFFFACC15),
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Badge Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: badgeGradient,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontFamily: 'Kantumruy Pro',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCompleted) ...[
                                const SizedBox(width: 3),
                                const Text(
                                  '✔',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Image Wrapper Box
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor, width: 2.5),
                            boxShadow: boxShadows,
                            color: const Color(0xFF1E293B),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15.5),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  thumbAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFF334155),
                                    child: Center(
                                      child: Text(
                                        '${widget.level.orderIndex}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Dark overlay & icons for locked states
                                if (!isUnlocked && !isSubLocked)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    child: const Center(
                                      child: Icon(
                                        Icons.lock_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  ),

                                if (isSubLocked)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    child: const Center(
                                      child: Text(
                                        '👑',
                                        style: TextStyle(fontSize: 26),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
