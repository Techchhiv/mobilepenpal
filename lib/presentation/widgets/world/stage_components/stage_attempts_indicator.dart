import 'package:flutter/material.dart';

/// A row of heart icons showing the number of attempts remaining.
///
/// Hidden when `attemptLeft >= maxAttempts`.
class StageAttemptsIndicator extends StatelessWidget {
  const StageAttemptsIndicator({
    super.key,
    required this.attemptLeft,
    required this.maxAttempts,
  });

  /// Current remaining attempt count.
  final int attemptLeft;

  /// The maximum number of attempts per exercise (e.g. 3).
  final int maxAttempts;

  @override
  Widget build(BuildContext context) {
    if (attemptLeft >= maxAttempts || attemptLeft <= 0) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxAttempts, (index) {
        final isFilled = index < attemptLeft;
        final isLastRemaining = attemptLeft == 1 && index == 0;

        final heartWidget = Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 28,
              ),
              Icon(
                Icons.favorite,
                color: isFilled ? Colors.redAccent : Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        );

        if (isLastRemaining) {
          return _FlashingHeart(child: heartWidget);
        }
        return heartWidget;
      }),
    );
  }
}

/// A helper widget to animate scale and opacity for a pulsing/beating heart warning.
class _FlashingHeart extends StatefulWidget {
  final Widget child;
  const _FlashingHeart({required this.child});

  @override
  State<_FlashingHeart> createState() => _FlashingHeartState();
}

class _FlashingHeartState extends State<_FlashingHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
