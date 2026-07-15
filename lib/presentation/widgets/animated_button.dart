import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A gesture detector that scales down slightly when pressed to give a bouncy sensation.
class BouncyGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BouncyGestureDetector({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<BouncyGestureDetector> createState() => _BouncyGestureDetectorState();
}

class _BouncyGestureDetectorState extends State<BouncyGestureDetector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

/// A loading loader animation for playful buttons with bouncing circles and spinning icon.
class PlayfulButtonLoader extends StatefulWidget {
  final Color color;
  final IconData? loaderIcon;

  const PlayfulButtonLoader({
    super.key,
    this.color = Colors.white,
    this.loaderIcon,
  });

  @override
  State<PlayfulButtonLoader> createState() => _PlayfulButtonLoaderState();
}

class _PlayfulButtonLoaderState extends State<PlayfulButtonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loaderIcon != null) ...[
          RotationTransition(
            turns: _controller,
            child: Icon(
              widget.loaderIcon!,
              color: widget.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
        ],
        ...List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              double value = (_controller.value - delay) % 1.0;
              double bounce = math.sin(value * math.pi);
              if (bounce < 0) bounce = 0;

              return Transform.translate(
                offset: Offset(0, 3.0 - bounce * 6.0),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

/// A playful button with 3D shadow style and a bounce animation when pressed.
class AnimatedButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;
  final IconData? loaderIcon;

  const AnimatedButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
    this.icon,
    this.isLoading = false,
    this.loaderIcon = Icons.stars_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isLoading ? Color.lerp(color, Colors.white, 0.2) ?? color : color;
    final shadowColor = Color.lerp(activeColor, Colors.black, 0.28) ?? Colors.black;

    return BouncyGestureDetector(
      onTap: isLoading ? () {} : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: activeColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0, 5),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: isLoading
                ? SizedBox(
                    height: 24,
                    child: PlayfulButtonLoader(
                      key: const ValueKey('loading'),
                      loaderIcon: loaderIcon,
                    ),
                  )
                : Row(
                    key: const ValueKey('normal'),
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
