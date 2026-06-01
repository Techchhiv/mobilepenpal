import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
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

  static const double _tileOriginalWidth = 440.0;
  static const double _tileOriginalHeight = 956.0;

  static const List<String> _bgTiles = [
    // "assets/images/backgrounds/map_background.png",
    "assets/images/backgrounds/map_background_1.png",
    "assets/images/backgrounds/map_background_2.png",
    "assets/images/backgrounds/map_background_3.png",
    "assets/images/backgrounds/map_background_4.png",
  ];

  /// Ensure user can scroll even if few levels.
  static const int _minTiles = 1;

  /// Distance between each level center
  static const double _levelSpacingDesign = 250.0;

  /// How far Level 1 center is from the very bottom of the scroll content.
  static const double _bottomInsetDesign = 150.0;

  /// Extra padding at the very top so last level isn't glued to edge.
  static const double _topInsetDesign = 250.0;

  /// Cap scaling so tablets don't get oversized spacing / zoomed background.
  static const double _maxScaleWidth = 500.0;

  /// LevelCircle size approximation for centering.
  static const double _bubbleSize = 82.0;

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

  double _scaleFactor(double screenWidth) =>
      min(screenWidth, _maxScaleWidth) / _tileOriginalWidth;
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
      final bool isCompleted = _progress01(level.completionPercentage) >= 1.0;
      final bool isUnlocked = _boolish(level.isUnlocked);

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

      final neededH = _requiredContentHeight(
        levelCount: levels.length,
        screenWidth: screenW,
      );

      final viewportH = MediaQuery.of(context).size.height;
      final contentH = max(neededH, viewportH);

      final spacing = _scaled(_levelSpacingDesign, screenW);
      final bottomInset = _scaled(_bottomInsetDesign, screenW);

      final idx = _findCurrentLevelIndex(levels);
      final targetY = _levelCenterY(
        levelIndex: idx,
        contentHeight: contentH,
        bottomInset: bottomInset,
        spacing: spacing,
      );

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
    final tileH = _tileHeight(screenW);

    final neededH = _requiredContentHeight(
      levelCount: levels.length,
      screenWidth: screenW,
    );

    final viewportH = MediaQuery.of(context).size.height;
    final contentH = max(neededH, viewportH);

    final tileCount = _tileCountForHeight(
      contentHeight: contentH,
      tileHeight: tileH,
    );

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
    required double contentHeight,
  }) {
    final asset = _bgTiles.isEmpty ? null : _bgTiles.first;

    if (tileCount <= 1) {
      return Positioned.fill(
        child: asset == null
            ? Container(color: Colors.grey.shade200)
            : Image.asset(
                asset,
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

  Widget _buildLevelsContinuous({
    required List<WorldLevel> levels,
    required double width,
    required double contentHeight,
    required double screenWidth,
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
        );
      }),
    );
  }
}

class LevelCircle extends StatelessWidget {
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

  bool get _isUnlocked => level.isUnlocked;

  bool get _isSubLocked => level.isLockedBySubscription == true;

  double get _progress =>
      ((level.completionPercentage) / 100.0).clamp(0.0, 1.0);

  bool get _isCompleted => _progress >= 1.0;

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = _isCompleted;
    final bool isSubLocked = _isSubLocked;
    final bool isUnlocked = _isUnlocked;
    final bool isLocked = !isUnlocked && !isSubLocked;
    final bool isCurrentActive = isCurrent && isUnlocked && !isCompleted;

    const double ring = 82;
    const double halo = 102;

    final title = (level.name).trim();

    // Design parameters based on states
    Gradient? backgroundGradient;
    Color backgroundColor = Colors.white;
    Gradient? borderGradient;
    Color borderColor = Colors.grey;
    double borderWidth = 3.0;
    Gradient? waveGradient;
    Color waveColor = AppColors.primary;

    if (isCurrentActive) {
      backgroundGradient = null;
      backgroundColor = Colors.white;
      borderGradient = const LinearGradient(
        colors: [Color(0xFF056E6D), Color(0xFF2EC4B6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
      borderWidth = 4.0;
      waveGradient = const LinearGradient(
        colors: [Color(0xFF056E6D), Color(0xFF2EC4B6)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );
    } else if (isCompleted) {
      backgroundGradient = const LinearGradient(
        colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderGradient = const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderWidth = 3.0;
    } else if (isSubLocked) {
      backgroundGradient = const LinearGradient(
        colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A), Color(0xFFFCD34D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderGradient = const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderWidth = 3.0;
    } else if (isUnlocked) {
      backgroundGradient = const RadialGradient(
        colors: [Colors.white, Color(0xFFE6F4F1)],
        radius: 0.8,
      );
      borderColor = const Color(0xFF2EC4B6).withValues(alpha: 0.60);
      borderWidth = 3.0;
    } else {
      backgroundGradient = const LinearGradient(
        colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderColor = const Color(0xFF9CA3AF);
      borderWidth = 2.5;
    }

    final bool animateWave = isUnlocked && !isCompleted && !isSubLocked;

    Widget body = SizedBox(
      width: ring,
      height: ring,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -50,
            child: _LevelTitlePill(
              text: title.isEmpty ? 'Level' : title,
              isCurrent: isCurrent,
              isUnlocked: isUnlocked,
              isSubLocked: isSubLocked,
              isCompleted: isCompleted,
            ),
          ),

          if (isCurrentActive) _GlowHalo(size: halo, animation: bounce),

          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: Container(
              width: ring,
              height: ring,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(level),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _WaveCirclePainter(
                              wave: animateWave ? wave : null,
                              amplitudeFactor: waveAmplitudeFactor,
                              amplitudeMin: waveAmplitudeMin,
                              wavelengthFactor: waveWavelengthFactor,
                              progress: isUnlocked ? _progress : 0.0,
                              locked: isLocked,
                              subLocked: isSubLocked,
                              completed: isCompleted,
                              backgroundGradient: backgroundGradient,
                              backgroundColor: backgroundColor,
                              borderGradient: borderGradient,
                              borderColor: borderColor,
                              borderWidth: borderWidth,
                              waveGradient: waveGradient,
                              waveColor: waveColor,
                            ),
                          ),
                        ),

                        if (isSubLocked)
                          Text(
                            '👑',
                            style: TextStyle(
                              fontSize: 30,
                              shadows: level.orderIndex == 1
                                  ? null
                                  : const [
                                      Shadow(
                                        color: Color(0xFFB45309),
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                            ),
                          )
                        else if (isCompleted)
                          Text(
                            '${level.orderIndex}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF15803D),
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          )
                        else if (isCurrentActive)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${level.orderIndex}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF056E6D),
                                  shadows: [
                                    Shadow(color: Colors.white, offset: Offset(-1.5, -1.5), blurRadius: 2),
                                    Shadow(color: Colors.white, offset: Offset(1.5, -1.5), blurRadius: 2),
                                    Shadow(color: Colors.white, offset: Offset(-1.5, 1.5), blurRadius: 2),
                                    Shadow(color: Colors.white, offset: Offset(1.5, 1.5), blurRadius: 2),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 1),
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: Color(0xFF056E6D),
                                size: 18,
                                shadows: [
                                  Shadow(color: Colors.white, offset: Offset(-1, -1), blurRadius: 1),
                                  Shadow(color: Colors.white, offset: Offset(1, -1), blurRadius: 1),
                                  Shadow(color: Colors.white, offset: Offset(-1, 1), blurRadius: 1),
                                  Shadow(color: Colors.white, offset: Offset(1, 1), blurRadius: 1),
                                ],
                              ),
                            ],
                          )
                        else if (isUnlocked)
                          Text(
                            '${level.orderIndex}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF056E6D),
                            ),
                          )
                        else
                          const Icon(
                            Icons.lock_rounded,
                            color: Colors.white,
                            size: 26,
                            shadows: [
                              Shadow(
                                color: Color(0xFF9CA3AF),
                                offset: Offset(0, 1.5),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (isCompleted)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),

          if (isSubLocked)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  '💎',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );

    if (!isCurrentActive) return body;

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


class _GlowHalo extends StatelessWidget {
  final double size;
  final Animation<double> animation;
  const _GlowHalo({required this.size, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final blur = 12.0 + 8.0 * animation.value;
        final spread = 1.0 + 3.0 * animation.value;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2EC4B6).withValues(alpha: 0.40 * (1.0 - animation.value * 0.2)),
                blurRadius: blur,
                spreadRadius: spread,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LevelTitlePill extends StatelessWidget {
  final String text;
  final bool isCurrent;
  final bool isUnlocked;
  final bool isSubLocked;
  final bool isCompleted;

  const _LevelTitlePill({
    required this.text,
    required this.isCurrent,
    required this.isUnlocked,
    required this.isSubLocked,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCurrentActive = isCurrent && isUnlocked && !isCompleted;

    Gradient? bgGradient;
    Color bgColor = Colors.white;
    Border? border;
    Color textColor = Colors.black;
    String displayText = text;

    if (isCurrentActive) {
      bgGradient = const LinearGradient(
        colors: [Color(0xFF056E6D), Color(0xFF2EC4B6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      textColor = Colors.white;
      displayText = text;
    } else if (isCompleted) {
      bgGradient = const LinearGradient(
        colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      textColor = Colors.white;
      displayText = text;
    } else if (isSubLocked) {
      bgGradient = const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      textColor = Colors.white;
      displayText = text;
    } else if (isUnlocked) {
      bgColor = Colors.white;
      border = Border.all(
        color: const Color(0xFF2EC4B6).withValues(alpha: 0.50),
        width: 1.5,
      );
      textColor = const Color(0xFF056E6D);
    } else {
      bgGradient = const LinearGradient(
        colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      textColor = const Color(0xFF9CA3AF);
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgGradient == null ? bgColor : null,
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(16),
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        displayText,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _WaveCirclePainter extends CustomPainter {
  final Animation<double>? wave;
  final double progress;
  final bool locked;
  final bool subLocked;
  final bool completed;

  final Gradient? backgroundGradient;
  final Color backgroundColor;
  final Gradient? borderGradient;
  final Color borderColor;
  final double borderWidth;
  final Gradient? waveGradient;
  final Color waveColor;

  final double amplitudeFactor;
  final double amplitudeMin;
  final double wavelengthFactor;

  _WaveCirclePainter({
    required this.wave,
    required this.progress,
    required this.locked,
    required this.subLocked,
    required this.completed,
    required this.backgroundGradient,
    required this.backgroundColor,
    required this.borderGradient,
    required this.borderColor,
    required this.borderWidth,
    required this.waveGradient,
    required this.waveColor,
    required this.amplitudeFactor,
    required this.amplitudeMin,
    required this.wavelengthFactor,
  }) : super(repaint: wave);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()..style = PaintingStyle.fill;
    if (backgroundGradient != null) {
      bgPaint.shader = backgroundGradient!.createShader(rect);
    } else {
      bgPaint.color = locked
          ? Colors.grey.shade400
          : (subLocked
                ? const Color(0xFFFFD700).withValues(alpha: 0.30)
                : (completed ? Colors.green : backgroundColor));
    }

    canvas.drawCircle(center, radius, bgPaint);

    if (!locked && !subLocked && !completed) {
      final clipPath = Path()..addOval(rect);
      canvas.save();
      canvas.clipPath(clipPath);

      final phase = (wave?.value ?? 0.0) * 2 * pi;
      final fillY = size.height * (1.0 - progress);

      final amp = max(amplitudeMin, size.height * amplitudeFactor);
      final wavelength = size.width * wavelengthFactor;
      final k = 2 * pi / wavelength;

      final wavePaint1 = Paint()..style = PaintingStyle.fill;
      if (waveGradient != null) {
        wavePaint1.shader = waveGradient!.createShader(
          Rect.fromLTWH(0, fillY - amp, size.width, size.height - fillY + amp),
        );
      } else {
        wavePaint1.color = waveColor.withValues(alpha: 0.85);
      }

      final path1 = Path()..moveTo(-size.width, fillY);
      for (double x = -size.width; x <= size.width * 2; x += 2) {
        final y = fillY + sin((x * k) + phase) * amp;
        path1.lineTo(x, y);
      }
      path1
        ..lineTo(size.width * 2, size.height)
        ..lineTo(-size.width, size.height)
        ..close();
      canvas.drawPath(path1, wavePaint1);

      final wavePaint2 = Paint()..style = PaintingStyle.fill;
      if (waveGradient != null) {
        wavePaint2.shader = LinearGradient(
          colors: [
            const Color(0xFF056E6D).withValues(alpha: 0.50),
            const Color(0xFF2EC4B6).withValues(alpha: 0.50),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(
          Rect.fromLTWH(0, fillY - amp * 0.6, size.width, size.height - fillY + amp * 0.6),
        );
      } else {
        wavePaint2.color = waveColor.withValues(alpha: 0.45);
      }

      final path2 = Path()..moveTo(-size.width, fillY);
      for (double x = -size.width; x <= size.width * 2; x += 2) {
        final y = fillY + sin((x * k) + phase + pi / 2) * (amp * 0.6);
        path2.lineTo(x, y);
      }
      path2
        ..lineTo(size.width * 2, size.height)
        ..lineTo(-size.width, size.height)
        ..close();
      canvas.drawPath(path2, wavePaint2);

      canvas.restore();
    }

    // Add subtle sparkle dots for completed levels
    if (completed) {
      final sparklePaint = Paint()..color = const Color(0xFFFEF08A);
      canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.35), 2.5, sparklePaint);
      canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.25), 1.8, sparklePaint);
      canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.7), 2.2, sparklePaint);
      canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.75), 1.5, sparklePaint);
    }

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    if (borderGradient != null) {
      borderPaint.shader = borderGradient!.createShader(rect);
    } else {
      borderPaint.color = borderColor;
    }
    canvas.drawCircle(center, radius - borderWidth / 2, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _WaveCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.locked != locked ||
        oldDelegate.subLocked != subLocked ||
        oldDelegate.completed != completed ||
        oldDelegate.waveColor != waveColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.amplitudeFactor != amplitudeFactor ||
        oldDelegate.amplitudeMin != amplitudeMin ||
        oldDelegate.wavelengthFactor != wavelengthFactor ||
        oldDelegate.wave != wave;
  }
}
