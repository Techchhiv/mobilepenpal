import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/core/config/env.dart';

class SummaryWidget extends StatefulWidget {
  final int starsEarned;
  final int correctAnswers;
  final int totalQuestions;
  final int? earnedCoins;
  final int? earnedXp;
  final VoidCallback onRetry;
  final VoidCallback onContinue;
  final VoidCallback? onClose;

  const SummaryWidget({
    super.key,
    required this.starsEarned,
    required this.correctAnswers,
    required this.totalQuestions,
    this.earnedCoins,
    this.earnedXp,
    required this.onRetry,
    required this.onContinue,
    this.onClose,
  });

  @override
  State<SummaryWidget> createState() => _SummaryWidgetState();
}

class _SummaryWidgetState extends State<SummaryWidget>
    with TickerProviderStateMixin {
  static const int maxStars = 3;
  late final List<AnimationController> starControllers;

  @override
  void initState() {
    super.initState();
    starControllers = List.generate(
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
    for (final c in starControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _startStarAnimations() async {
    if (widget.starsEarned <= 0) return;

    await Future.delayed(const Duration(milliseconds: 400));

    for (var i = 0; i < widget.starsEarned && i < maxStars; i++) {
        if (!mounted) return;
      final c = starControllers[i];
      c.reset();
      c.forward();
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            "assets/images/backgrounds/summary_background.png",
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2B7A78).withValues(alpha: 1),
                  const Color(0xFF6B9F8E).withValues(alpha: 0.8),
                  const Color(0xFF8FB99F).withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
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
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: widget.onClose != null
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onClose,
              )
            : const SizedBox(height: 48),
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
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Lottie.asset("assets/animated/trophy.json", repeat: false),
    );
  }

  Widget _buildScore() {
    final rawScore = '${widget.correctAnswers}/${widget.totalQuestions}';
    final score = NumberFormatUtils.digitsByLocale(rawScore);

    final msgKey = _encouragementKey(
      stars: widget.starsEarned,
      correct: widget.correctAnswers,
      total: widget.totalQuestions,
    );

    return Column(
      children: [
        Text(
          score,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          msgKey.tr,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        if ((widget.earnedCoins != null && widget.earnedCoins! > 0) ||
            (widget.earnedXp != null && widget.earnedXp! > 0)) ...[
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              if (widget.earnedCoins != null && widget.earnedCoins! > 0)
                _buildRewardChip(
                  icon: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.circle, color: Colors.yellow.shade700, size: 24),
                      const Icon(Icons.attach_money, color: Colors.white, size: 16),
                    ],
                  ),
                  value:
                      '+${NumberFormatUtils.digitsByLocale(widget.earnedCoins.toString())}',
                ),
              if (widget.earnedXp != null && widget.earnedXp! > 0)
                _buildRewardChip(
                  icon: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFC46B), Color(0xFFFF8A3D)],
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                  value:
                      '+${NumberFormatUtils.digitsByLocale(widget.earnedXp.toString())} XP',
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRewardChip({required Widget icon, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarDisplay() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(maxStars, (index) {
          final isEarned = index < widget.starsEarned;

          final dy = index == 1 ? -18.0 : 6.0;

          return Transform.translate(
            offset: Offset(0, dy),
            child: SizedBox(
              width: 120,
              height: 120,
              child: Lottie.asset(
                isEarned
                    ? 'assets/animated/star.json'
                    : 'assets/animated/star_border.json',
                controller: isEarned ? starControllers[index] : null,
                onLoaded: isEarned
                    ? (composition) {
                        starControllers[index].duration = composition.duration;
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Env.globalMaxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.onRetry,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1FB9FF),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.replay, color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: widget.onContinue,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 32,
                      ),
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

  String _encouragementKey({
    required int stars,
    required int correct,
    required int total,
  }) {
    if (total <= 0) return 'summary_good_try';

    final accuracy = correct / total;

    if (stars >= 3 || accuracy >= 0.999) return 'summary_perfect';

    if (stars == 2 || accuracy >= 0.50) return 'summary_great';

    return 'summary_good_try';
  }
}
