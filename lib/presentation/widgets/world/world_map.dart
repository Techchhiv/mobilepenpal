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

  /// LevelCircle size approximation for centering.
  static const double _bubbleSize = 72.0;

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

  double _effectiveScreenWidth(double screenWidth) => min(screenWidth, 600.0);

  double _scaleFactor(double screenWidth) => _effectiveScreenWidth(screenWidth) / _tileOriginalWidth;
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
      _showSnackBar('👑 ${'subscribe_to_unlock'.tr}', const Color(0xFFB8860B));
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
            : Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(asset),
                    fit: BoxFit.fitHeight,
                    repeat: ImageRepeat.repeatX,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
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
          child: Container(
            width: width,
            height: tileHeight,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(a),
                fit: BoxFit.fitHeight,
                repeat: ImageRepeat.repeatX,
                alignment: Alignment.bottomCenter,
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

  bool get _isUnlocked =>
      level.isUnlocked == true ||
      level.isUnlocked == 1 ||
      level.isUnlocked == '1';

  bool get _isSubLocked => level.isLockedBySubscription == true;

  double get _progress =>
      ((level.completionPercentage) / 100.0).clamp(0.0, 1.0);

  bool get _isCompleted => _progress >= 1.0;

  @override
  Widget build(BuildContext context) {
    final bool animateThisOne = isCurrent && _isUnlocked && !_isCompleted;

    const double ring = 72;
    const double halo = 90;

    final title = (level.name).trim();

    final Color borderColor = _isSubLocked
        ? const Color(0xFFB8860B)
        : (_isCompleted
              ? Colors.green.shade700
              : (isCurrent ? AppColors.primary : Colors.blue.shade700));

    final Color waveColor = _isCompleted
        ? Colors.green.shade600
        : Colors.blue.shade600;

    final bool animateWave = _isUnlocked && !_isCompleted && !_isSubLocked;

    Widget body = SizedBox(
      width: ring,
      height: ring,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -52,
            child: _LevelTitlePill(
              text: title.isEmpty ? 'Level' : title,
              isCurrent: isCurrent,
              isUnlocked: _isUnlocked,
              isSubLocked: _isSubLocked,
            ),
          ),

          if (animateThisOne) _GlowHalo(size: halo),

          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: Ink(
              width: ring,
              height: ring,
              child: InkWell(
                customBorder: const CircleBorder(),
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
                          progress: _isUnlocked ? _progress : 0.0,
                          locked: !_isUnlocked && !_isSubLocked,
                          subLocked: _isSubLocked,
                          completed: _isCompleted,
                          waveColor: waveColor,
                          backgroundColor: Colors.white.withValues(alpha: 0.92),
                          borderColor: borderColor,
                        ),
                      ),
                    ),

                    if (_isSubLocked)
                      const Text('👑', style: TextStyle(fontSize: 22))
                    else if (_isUnlocked)
                      _NumberBadge(text: '${level.orderIndex}')
                    else
                      const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 22,
                      ),

                    if (_isCompleted)
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
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!animateThisOne) return body;

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

class _NumberBadge extends StatelessWidget {
  final String text;
  const _NumberBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          height: 1.0,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _GlowHalo extends StatelessWidget {
  final double size;
  const _GlowHalo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.buttonPrimary.withValues(alpha: 0.30),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _LevelTitlePill extends StatelessWidget {
  final String text;
  final bool isCurrent;
  final bool isUnlocked;
  final bool isSubLocked;

  const _LevelTitlePill({
    required this.text,
    required this.isCurrent,
    required this.isUnlocked,
    required this.isSubLocked,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Colors.white;
    final borderColor = isSubLocked
        ? const Color(0xFFB8860B)
        : (isCurrent
              ? AppColors.primary
              : Colors.green.withValues(alpha: 0.10));
    final fg = (isUnlocked || isSubLocked)
        ? Colors.black
        : Colors.black.withValues(alpha: 0.60);

    return Container(
      constraints: BoxConstraints(maxWidth: 170),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: (isCurrent || isSubLocked) ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
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
          fontSize: 16,
          fontWeight: FontWeight.w800,
          height: 1.05,
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

  final Color waveColor;
  final Color backgroundColor;
  final Color borderColor;

  final double amplitudeFactor;
  final double amplitudeMin;
  final double wavelengthFactor;

  _WaveCirclePainter({
    required this.wave,
    required this.progress,
    required this.locked,
    required this.subLocked,
    required this.completed,
    required this.waveColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.amplitudeFactor,
    required this.amplitudeMin,
    required this.wavelengthFactor,
  }) : super(repaint: wave);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final baseColor = locked
        ? Colors.grey.shade400
        : (subLocked
              ? const Color(0xFFFFD700).withValues(alpha: 0.30)
              : (completed ? Colors.green : backgroundColor));

    final bgPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

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

      final wavePaint1 = Paint()..color = waveColor.withValues(alpha: 0.85);
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

      final wavePaint2 = Paint()..color = waveColor.withValues(alpha: 0.45);
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

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 1.5, borderPaint);
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
        oldDelegate.amplitudeFactor != amplitudeFactor ||
        oldDelegate.amplitudeMin != amplitudeMin ||
        oldDelegate.wavelengthFactor != wavelengthFactor ||
        oldDelegate.wave != wave;
  }
}
