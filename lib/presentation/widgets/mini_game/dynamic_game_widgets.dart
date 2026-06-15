import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/mini_game/dynamic_mini_game_controller.dart';
import 'package:mobilepenpal/data/models/mini_game/mini_game_model.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';

class GameColors {
  static const Color skyTop = Color(0xFF7EC8E3);
  static const Color skyMid = Color(0xFFB5E8D5);
  static const Color skyBot = Color(0xFF9BD8A5);
  static const Color card = Color(0xFFFFFDF7);
  static const Color cardBorder = Color(0xFFE8E4DA);
  static const Color teal = Color(0xFF3CBBB1);
  static const Color green = Color(0xFF5DC97E);
  static const Color gold = Color(0xFFFFCB45);
  static const Color orange = Color(0xFFFFAB5E);
  static const Color pink = Color(0xFFFF8FAB);
  static const Color softRed = Color(0xFFF87171);
  static const Color purple = Color(0xFFA78BFA);
  static const Color textDark = Color(0xFF3D405B);
  static const Color textMuted = Color(0xFF8E91A4);

  static const List<Color> pastels = [
    Color(0xFFFFF3E0), // peach
    Color(0xFFE8F5E9), // mint
    Color(0xFFE3F2FD), // sky
    Color(0xFFFCE4EC), // blush
    Color(0xFFF3E5F5), // lavender
    Color(0xFFFFF9C4), // lemon
  ];

  static const List<Color> pastelBorders = [
    Color(0xFFFFCC80),
    Color(0xFF81C784),
    Color(0xFF64B5F6),
    Color(0xFFF48FB1),
    Color(0xFFCE93D8),
    Color(0xFFFFF176),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  GAME BACKGROUND — Sky gradient + soft clouds + floating Khmer letters
// ═══════════════════════════════════════════════════════════════════════════
class GameBackground extends StatelessWidget {
  const GameBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient sky
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GameColors.skyTop,
                  GameColors.skyMid,
                  GameColors.skyBot,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        // Soft hill shapes at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 140,
          child: CustomPaint(painter: _HillsPainter()),
        ),
        // Clouds
        const Positioned(
          top: 40,
          left: 20,
          child: _Cloud(width: 80, opacity: 0.25),
        ),
        const Positioned(
          top: 80,
          right: 30,
          child: _Cloud(width: 60, opacity: 0.18),
        ),
        const Positioned(
          top: 180,
          left: 60,
          child: _Cloud(width: 50, opacity: 0.12),
        ),
        // Floating Khmer letters
        const FloatingKhmerDecoration(),
      ],
    );
  }
}

class _Cloud extends StatelessWidget {
  const _Cloud({required this.width, required this.opacity});
  final double width;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: width * 0.45,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(width),
        ),
      ),
    );
  }
}

class _HillsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = const Color(0xFF8FCE9E).withValues(alpha: 0.45);
    final path1 = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.25,
        0,
        size.width * 0.5,
        size.height * 0.4,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.8,
        size.width,
        size.height * 0.3,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path1, p1);

    final p2 = Paint()..color = const Color(0xFFA8D8B5).withValues(alpha: 0.4);
    final path2 = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.2,
        size.width * 0.65,
        size.height * 0.65,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.9,
        size.width,
        size.height * 0.5,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path2, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
//  FLOATING KHMER DECORATION — slowly drifting letters, stars, sparkles
// ═══════════════════════════════════════════════════════════════════════════
class FloatingKhmerDecoration extends StatefulWidget {
  const FloatingKhmerDecoration({super.key});

  @override
  State<FloatingKhmerDecoration> createState() =>
      _FloatingKhmerDecorationState();
}

class _FloatingKhmerDecorationState extends State<FloatingKhmerDecoration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_FloatingItem> _items;

  static const _letters = ['ក', 'ខ', 'គ', 'ឃ', 'ង', '⭐', '✨', '💎'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    final rng = math.Random(42);
    _items = List.generate(10, (i) {
      return _FloatingItem(
        char: _letters[i % _letters.length],
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        speed: 0.3 + rng.nextDouble() * 0.7,
        size: 14.0 + rng.nextDouble() * 10,
        opacity: 0.08 + rng.nextDouble() * 0.12,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          children: _items.map((item) {
            final t = (_ctrl.value * item.speed) % 1.0;
            final y = (item.y + t) % 1.1;
            return Positioned(
              left: item.x * MediaQuery.of(context).size.width,
              top: y * MediaQuery.of(context).size.height,
              child: Opacity(
                opacity: item.opacity,
                child: Text(
                  item.char,
                  style: TextStyle(fontSize: item.size, color: Colors.white),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FloatingItem {
  final String char;
  final double x, y, speed, size, opacity;
  const _FloatingItem({
    required this.char,
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
//  SCORE CHIP — Animated counting score display
// ═══════════════════════════════════════════════════════════════════════════
class ScoreChip extends StatelessWidget {
  const ScoreChip({super.key, required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: GameColors.gold.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TweenAnimationBuilder<int>(
        tween: IntTween(begin: score, end: score),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, _) {
          return Center(
            child: Text(
              '$value',
              style: TextStyle(
                color: GameColors.textDark,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: Get.locale?.languageCode == 'km' ? 0 : 1,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ANIMATED SCORE CHIP — Wrapper that counts up from old→new score
// ═══════════════════════════════════════════════════════════════════════════
class AnimatedScoreChip extends StatefulWidget {
  const AnimatedScoreChip({super.key, required this.score});
  final int score;

  @override
  State<AnimatedScoreChip> createState() => _AnimatedScoreChipState();
}

class _AnimatedScoreChipState extends State<AnimatedScoreChip>
    with SingleTickerProviderStateMixin {
  late int _displayScore;
  late int _previousScore;
  late AnimationController _ctrl;
  late Animation<int> _countAnim;

  @override
  void initState() {
    super.initState();
    _displayScore = widget.score;
    _previousScore = widget.score;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _countAnim = IntTween(
      begin: _previousScore,
      end: _displayScore,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant AnimatedScoreChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _previousScore = _displayScore;
      _displayScore = widget.score;
      _countAnim = IntTween(
        begin: _previousScore,
        end: _displayScore,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: GameColors.gold.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _countAnim,
        builder: (context, _) {
          return Center(
            child: Text(
              '${_countAnim.value}',
              style: TextStyle(
                color: GameColors.textDark,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: Get.locale?.languageCode == 'km' ? 0 : 1,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  DIFFICULTY CHIP — Shows Easy / Medium / Hard with friendly colors
// ═══════════════════════════════════════════════════════════════════════════
class DifficultyChip extends StatelessWidget {
  const DifficultyChip({super.key, required this.difficulty, this.onTap});
  final MiniGameDifficulty difficulty;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    switch (difficulty) {
      case MiniGameDifficulty.easy:
        label = 'E';
        color = GameColors.teal;
      case MiniGameDifficulty.medium:
        label = 'M';
        color = GameColors.orange;
      case MiniGameDifficulty.hard:
        label = 'H';
        color = GameColors.pink;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  COIN CHIP — Gold-themed chip showing earned coins with coin icon
// ═══════════════════════════════════════════════════════════════════════════
class CoinChip extends StatelessWidget {
  const CoinChip({super.key, required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GameColors.gold.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: GameColors.gold.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: GameColors.gold,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              color: GameColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
class PillIconButton extends StatelessWidget {
  const PillIconButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.8),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: GameColors.textDark, size: 22),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TIMER BAR — Playful capsule with glow and clock icon
// ═══════════════════════════════════════════════════════════════════════════
class TimerBar extends StatelessWidget {
  const TimerBar({super.key, required this.fraction});
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final clamped = fraction.clamp(0.0, 1.0);
    Color barColor;
    if (clamped > 0.5) {
      barColor = GameColors.teal;
    } else if (clamped > 0.25) {
      barColor = GameColors.gold;
    } else {
      barColor = GameColors.softRed;
    }

    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          color: barColor.withValues(alpha: 0.7),
          size: 18,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: Colors.white.withValues(alpha: 0.4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  gradient: LinearGradient(
                    colors: [barColor, barColor.withValues(alpha: 0.7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  COMBO INDICATOR — "2x Streak! ⭐"
// ═══════════════════════════════════════════════════════════════════════════
class ComboIndicator extends StatelessWidget {
  const ComboIndicator({super.key, required this.combo});
  final int combo;

  String _toKhmerDigits(int n) {
    const kmDigits = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
    return n.toString().split('').map((d) => kmDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context) {
    if (combo < 2) return const SizedBox(height: 28);
    final isHot = combo >= 5;
    final bgColor = isHot
        ? const Color(0xFFFF6B6B) // vivid red for hot streaks
        : const Color(0xFFFF9F43); // warm orange for normal streaks
    final isKhmer = Get.locale?.languageCode == 'km';
    final comboText = isKhmer ? _toKhmerDigits(combo) : combo.toString();

    return Container(
      height: 28,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isHot
                  ? Icons.local_fire_department_rounded
                  : Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'combo_streak'.trParams({'combo': comboText}),
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: Get.locale?.languageCode == 'km' ? 0 : 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  GAME ACTION BUTTON — Large rounded button (Clear / Submit / Play Again)
// ═══════════════════════════════════════════════════════════════════════════
class GameActionButton extends StatelessWidget {
  const GameActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  COUNTDOWN OVERLAY — Colorful bubble with 3, 2, 1, GO!
// ═══════════════════════════════════════════════════════════════════════════
class CountdownOverlay extends StatelessWidget {
  const CountdownOverlay({
    super.key,
    required this.controller,
    required this.countdownValue,
    required this.animCtrl,
  });
  final DynamicMiniGameController controller;
  final int countdownValue;
  final AnimationController animCtrl;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: AnimatedBuilder(
            animation: animCtrl,
            builder: (_, __) {
              final scale = 1.0 + (1.0 - animCtrl.value) * 0.5;
              final opacity = (1.0 - animCtrl.value * 0.3).clamp(0.0, 1.0);
              final val = countdownValue;
              String text;
              if (val > 0) {
                if (Get.locale?.languageCode == 'km') {
                  const kmDigits = [
                    '០',
                    '១',
                    '២',
                    '៣',
                    '៤',
                    '៥',
                    '៦',
                    '៧',
                    '៨',
                    '៩',
                  ];
                  text = val <= 9 ? kmDigits[val] : '$val';
                } else {
                  text = '$val';
                }
              } else {
                text = 'go_exclamation'.tr;
              }
              final isGo = val <= 0;
              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: isGo ? 160 : 120,
                    height: isGo ? 160 : 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isGo
                            ? [GameColors.teal, GameColors.green]
                            : [GameColors.gold, GameColors.orange],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isGo ? GameColors.teal : GameColors.gold)
                              .withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      text,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isGo ? 42 : 56,
                        fontWeight: FontWeight.w900,
                        letterSpacing: Get.locale?.languageCode == 'km' ? 0 : 2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  FEEDBACK OVERLAY — Celebratory / Gentle
// ═══════════════════════════════════════════════════════════════════════════
class FeedbackOverlay extends StatelessWidget {
  const FeedbackOverlay({super.key, required this.controller});
  final DynamicMiniGameController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: controller.feedbackAnimCtrl,
          builder: (_, __) {
            if (controller.feedbackAnimCtrl.value == 0) {
              return const SizedBox.shrink();
            }
            return Obx(() {
              final text = controller.feedbackText.value;
              if (text.isEmpty) return const SizedBox.shrink();
              final isCorrect = controller.isCorrectFeedback.value;
              final color = isCorrect
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFC62828);
              final bgColor = isCorrect
                  ? const Color(0xFFE8F5E9) // very light green, opaque
                  : const Color(0xFFFFEBEE); // very light red, opaque
              final opacity = (1.0 - controller.feedbackAnimCtrl.value).clamp(
                0.0,
                1.0,
              );
              final t = controller.feedbackAnimCtrl.value;
              final scaleVal = 0.6 + (math.sin(t * math.pi * 0.5) * 0.6);
              final yOffset = -30 * t;

              return Align(
                alignment: Alignment.center,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, yOffset),
                    child: Transform.scale(
                      scale: scaleVal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: color, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCorrect
                                  ? Icons.star_rounded
                                  : Icons.refresh_rounded,
                              color: color,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              text,
                              style: TextStyle(
                                color: color,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: Get.locale?.languageCode == 'km'
                                    ? 0
                                    : 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PAUSE DIALOG — Rounded, child-friendly
// ═══════════════════════════════════════════════════════════════════════════
class GamePauseDialog extends StatelessWidget {
  const GamePauseDialog({
    super.key,
    required this.onResume,
    required this.onQuit,
  });
  final VoidCallback onResume;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: GameColors.card,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: GameColors.teal.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pause_rounded,
                color: GameColors.teal,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            // Text(
            //   'paused'.tr,
            //   style: const TextStyle(color: GameColors.textDark, fontSize: 28, fontWeight: FontWeight.w900),
            // ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: Text(
                  'keep_playing'.tr,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onQuit,
                icon: const Icon(Icons.home_rounded, size: 22),
                label: Text(
                  'go_home'.tr,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GameColors.pink,
                  side: const BorderSide(color: GameColors.pink, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  INSTRUCTION CARD — Icon + short instruction per input type
// ═══════════════════════════════════════════════════════════════════════════
class InstructionBadge extends StatelessWidget {
  const InstructionBadge({super.key, required this.inputType});
  final String inputType;

  @override
  Widget build(BuildContext context) {
    String text;
    IconData icon;
    switch (inputType) {
      case 'drawing_board':
        text = 'trace_the_answer'.tr;
        icon = Icons.edit_rounded;
      case 'multiple_choice':
        text = 'pick_the_answer'.tr;
        icon = Icons.touch_app_rounded;
      case 'drag_and_drop':
        text = 'match_the_cards'.tr;
        icon = Icons.compare_arrows_rounded;
      default:
        text = 'play_exclamation'.tr;
        icon = Icons.play_arrow_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: GameColors.teal, size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: GameColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STAT ROW — For game over screen
// ═══════════════════════════════════════════════════════════════════════════
class StatRow extends StatelessWidget {
  const StatRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon!, color: color, size: 22),
            const SizedBox(width: 10),
          ],
          Text(
            label,
            style: TextStyle(
              color: GameColors.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
String _formatOptionText(String opt) {
  final parsed = NumberFormatUtils.parseIntAny(opt);
  if (parsed != null) {
    return NumberFormatUtils.intText(parsed);
  }
  return opt;
}

// ═══════════════════════════════════════════════════════════════════════════
//  CHOICE CARD — Animated, child-friendly Multiple Choice card
// ═══════════════════════════════════════════════════════════════════════════
class ChoiceCard extends StatefulWidget {
  const ChoiceCard({
    super.key,
    required this.option,
    required this.colorIndex,
    required this.onTap,
    this.isWrong = false,
  });
  final String option;
  final int colorIndex;
  final VoidCallback onTap;
  final bool isWrong;

  @override
  State<ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<ChoiceCard>
    with TickerProviderStateMixin {
  // ── Entrance animation (pop-in with overshoot) ──
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceOpacity;

  // ── Idle breathing animation (subtle scale pulse) ──
  late final AnimationController _breatheCtrl;

  // ── Tap press animation (squish-bounce) ──
  late final AnimationController _tapCtrl;
  late final Animation<double> _tapScale;

  // ── Wrong-answer shake ──
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeOffset;

  bool _wasWrong = false;

  // Pastel emoji decorations per index for visual fun
  static const _cardEmojis = ['🌟', '🎈', '🌸', '🦋', '🍎', '⭐', '🎨', '🌈'];

  @override
  void initState() {
    super.initState();

    // Entrance: staggered by colorIndex
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entranceScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.elasticOut),
    );
    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    // Stagger: each card waits (colorIndex * 80ms) before popping in
    Future.delayed(Duration(milliseconds: widget.colorIndex * 80), () {
      if (mounted) _entranceCtrl.forward();
    });

    // Idle breathing: gentle scale oscillation
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Tap press: quick squish-and-bounce
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tapScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.08)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_tapCtrl);

    // Shake: horizontal oscillation for wrong answers
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -3), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant ChoiceCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger shake when newly marked wrong
    if (widget.isWrong && !_wasWrong) {
      _shakeCtrl.forward(from: 0);
    }
    _wasWrong = widget.isWrong;

    // Re-trigger entrance if options changed (new challenge)
    if (oldWidget.option != widget.option) {
      _entranceCtrl.reset();
      Future.delayed(Duration(milliseconds: widget.colorIndex * 80), () {
        if (mounted) _entranceCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _breatheCtrl.dispose();
    _tapCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isWrong) return;
    _tapCtrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isWrong
        ? GameColors.cardBorder
        : GameColors.pastels[widget.colorIndex % GameColors.pastels.length];
    final borderColor = widget.isWrong
        ? GameColors.textMuted
        : GameColors.pastelBorders[
            widget.colorIndex % GameColors.pastelBorders.length];
    final textColor =
        widget.isWrong ? GameColors.textMuted : GameColors.textDark;
    final emoji = _cardEmojis[widget.colorIndex % _cardEmojis.length];

    return AnimatedBuilder(
      animation: Listenable.merge([
        _entranceCtrl,
        _breatheCtrl,
        _tapCtrl,
        _shakeCtrl,
      ]),
      builder: (context, child) {
        // Combine scales
        final entranceScale = _entranceScale.value;
        final breatheScale = widget.isWrong
            ? 1.0
            : 1.0 + (_breatheCtrl.value * 0.02); // ±2% pulse
        final tapScale = _tapCtrl.isAnimating ? _tapScale.value : 1.0;
        final combinedScale = entranceScale * breatheScale * tapScale;

        // Shake offset
        final dx = _shakeCtrl.isAnimating ? _shakeOffset.value : 0.0;

        return Opacity(
          opacity: _entranceOpacity.value,
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(
              scale: combinedScale,
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.isWrong ? null : _handleTap,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 3),
            boxShadow: widget.isWrong
                ? []
                : [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // Tiny emoji badge in the top-left corner
              Positioned(
                top: 6,
                left: 8,
                child: Opacity(
                  opacity: widget.isWrong ? 0.2 : 0.5,
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              // Main text centered
              Center(
                child: Text(
                  _formatOptionText(widget.option),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MATCH CARD — For Drag and Drop pairs
// ═══════════════════════════════════════════════════════════════════════════
class MatchCard extends StatefulWidget {
  const MatchCard({
    super.key,
    required this.content,
    required this.state,
    required this.onTap,
    this.scale = 1.0,
    this.colorIndex = 0,
  });

  final String content;
  // states: normal, selected, matched, wrong
  final String state;
  final VoidCallback onTap;
  final double scale;
  final int colorIndex;

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceScale;
  
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeOffset;

  late final AnimationController _popCtrl;
  late final Animation<double> _popScale;

  late final AnimationController _breatheCtrl;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entranceScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.elasticOut),
    );
    Future.delayed(Duration(milliseconds: widget.colorIndex * 80), () {
      if (mounted) _entranceCtrl.forward();
    });

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));

    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _popScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.95), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _popCtrl, curve: Curves.easeInOut));

    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    if (widget.state == 'wrong') {
      _shakeCtrl.forward(from: 0);
    } else if (widget.state == 'matched') {
      _popCtrl.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant MatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.state == 'wrong' && oldWidget.state != 'wrong') {
      _shakeCtrl.forward(from: 0);
    }
    if (widget.state == 'matched' && oldWidget.state != 'matched') {
      _popCtrl.forward(from: 0);
    }

    if (oldWidget.content != widget.content) {
      _entranceCtrl.reset();
      Future.delayed(Duration(milliseconds: widget.colorIndex * 80), () {
        if (mounted) _entranceCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _shakeCtrl.dispose();
    _popCtrl.dispose();
    _breatheCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleVal = widget.scale;
    final state = widget.state;
    final content = widget.content;

    Color bgColor = GameColors.card;
    Color borderColor = GameColors.cardBorder;
    Color textColor = GameColors.textDark;

    if (state == 'selected') {
      bgColor = GameColors.teal.withValues(alpha: 0.15);
      borderColor = GameColors.teal;
    } else if (state == 'matched') {
      bgColor = GameColors.green.withValues(alpha: 0.2);
      borderColor = GameColors.green;
      textColor = GameColors.green;
    } else if (state == 'wrong') {
      bgColor = GameColors.softRed.withValues(alpha: 0.15);
      borderColor = GameColors.softRed;
      textColor = GameColors.softRed;
    } else {
      bgColor = GameColors.pastels[widget.colorIndex % GameColors.pastels.length];
      borderColor = GameColors.pastelBorders[widget.colorIndex % GameColors.pastelBorders.length];
    }

    Widget innerContent;
    if (content == '🔊') {
      innerContent = Icon(
        Icons.volume_up_rounded,
        size: 32 * scaleVal,
        color: textColor,
      );
    } else if (content.contains('|')) {
      final parts = content.split('|');
      final img = parts[0];
      final txt = parts[1];
      innerContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (img.isNotEmpty)
            Image.asset(img, height: 44 * scaleVal, fit: BoxFit.contain),
          if (txt.isNotEmpty) ...[
            SizedBox(height: 4 * scaleVal),
            Text(
              txt,
              style: TextStyle(
                fontSize: 22 * scaleVal,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ],
      );
    } else if (content.startsWith('assets/') && content.contains('*')) {
      final starIndex = content.lastIndexOf('*');
      final imgPath = content.substring(0, starIndex);
      final count = int.tryParse(content.substring(starIndex + 1)) ?? 1;
      innerContent = Container(
        constraints: BoxConstraints(maxWidth: 130 * scaleVal),
        child: Wrap(
          spacing: 4 * scaleVal,
          runSpacing: 4 * scaleVal,
          alignment: WrapAlignment.center,
          children: List.generate(
            count,
            (_) => Image.asset(
              imgPath,
              width: 38 * scaleVal,
              height: 38 * scaleVal,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    } else if (content.startsWith('assets/')) {
      innerContent = Image.asset(
        content,
        height: 44 * scaleVal,
        fit: BoxFit.contain,
      );
    } else {
      innerContent = Text(
        _formatOptionText(content),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 28 * scaleVal,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return GestureDetector(
      onTap: (state == 'matched' || state == 'wrong') ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_entranceCtrl, _shakeCtrl, _popCtrl, _breatheCtrl]),
        builder: (context, child) {
          final entranceVal = _entranceScale.value;
          final shakeVal = _shakeCtrl.isAnimating ? _shakeOffset.value : 0.0;
          final popVal = _popCtrl.isAnimating ? _popScale.value : 1.0;
          
          final breatheVal = state == 'selected'
              ? 1.0 + (_breatheCtrl.value * 0.03)
              : 1.0;

          final combinedScale = entranceVal * popVal * breatheVal;

          return Transform.translate(
            offset: Offset(shakeVal, 0),
            child: Transform.scale(
              scale: combinedScale,
              child: child,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(
            vertical: 10 * scaleVal,
            horizontal: 8 * scaleVal,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: state == 'selected' ? 3.5 : 2.5,
            ),
            boxShadow: state == 'selected'
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.45),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Center(
                child: FittedBox(fit: BoxFit.scaleDown, child: innerContent),
              ),
              if (state == 'matched')
                const Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 16,
                  ),
                ),
              if (state == 'wrong')
                const Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    Icons.cancel_rounded,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  FLOATING SCORE OVERLAY — renders all active floating "+N" popups
// ═══════════════════════════════════════════════════════════════════════════
class FloatingScoreOverlay extends StatelessWidget {
  const FloatingScoreOverlay({super.key, required this.controller});
  final DynamicMiniGameController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final events = controller.floatingScores;
      if (events.isEmpty) return const SizedBox.shrink();
      return Stack(
        children: events
            .map((e) => _FloatingScoreAnimation(key: ValueKey(e.id), event: e))
            .toList(),
      );
    });
  }
}

/// A single floating "+N" that pops in → hovers → flies up toward the top bar.
class _FloatingScoreAnimation extends StatefulWidget {
  const _FloatingScoreAnimation({super.key, required this.event});
  final FloatingScoreEvent event;

  @override
  State<_FloatingScoreAnimation> createState() =>
      _FloatingScoreAnimationState();
}

class _FloatingScoreAnimationState extends State<_FloatingScoreAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Phase timing (total 1.2s = 1200ms):
  //   0.00 – 0.25: pop up (scale 0→1, fade in)
  //   0.25 – 0.55: hover in place
  //   0.55 – 1.00: fly upward and fade out
  static const _popEnd = 0.25;
  static const _hoverEnd = 0.55;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final startX = widget.event.startX * screenW;
    final startY = widget.event.startY * screenH;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;

        // Scale: pop in with bounce, then shrink during fly phase
        double scale;
        if (t < _popEnd) {
          final popT = (t / _popEnd).clamp(0.0, 1.0);
          scale = Curves.elasticOut.transform(popT);
        } else if (t < _hoverEnd) {
          scale = 1.0;
        } else {
          final flyT = ((t - _hoverEnd) / (1.0 - _hoverEnd)).clamp(0.0, 1.0);
          scale = 1.0 - flyT * 0.4;
        }

        // Opacity: fade in during pop, full during hover, fade out during fly
        double opacity;
        if (t < _popEnd) {
          opacity = (t / _popEnd).clamp(0.0, 1.0);
        } else if (t < _hoverEnd) {
          opacity = 1.0;
        } else {
          final flyT = ((t - _hoverEnd) / (1.0 - _hoverEnd)).clamp(0.0, 1.0);
          opacity = (1.0 - Curves.easeIn.transform(flyT)).clamp(0.0, 1.0);
        }

        // Position: stay in place, then fly toward center-top (Score Bar)
        double currentX = startX;
        double currentY = startY;

        if (t >= _hoverEnd) {
          final flyT = ((t - _hoverEnd) / (1.0 - _hoverEnd)).clamp(0.0, 1.0);
          final easeFlyT = Curves.easeInCubic.transform(flyT);

          final targetX = screenW / 2;
          final targetY = 50.0; // Approximate center of top bar

          currentX = startX + (targetX - startX) * easeFlyT;
          currentY = startY + (targetY - startY) * easeFlyT;
        }

        return Positioned(
          left: currentX - 30, // Center based on approximate text width
          top: currentY - 20,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Text(
        '+${widget.event.points}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: Get.locale?.languageCode == 'km' ? 0 : 2,
          shadows: [
            // Multiple dark shadows create a thick outline/stroke effect
            Shadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 0,
              offset: const Offset(1, 1),
            ),
            Shadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 0,
              offset: const Offset(-1, -1),
            ),
            Shadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 0,
              offset: const Offset(1, -1),
            ),
            Shadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 0,
              offset: const Offset(-1, 1),
            ),
            Shadow(
              color: GameColors.gold.withValues(alpha: 0.7),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}
