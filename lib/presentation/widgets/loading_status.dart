import 'package:flutter/material.dart';
import 'package:get/utils.dart';

class LoadingStatus extends StatefulWidget {
  final bool isLoading;
  final bool isSuccess;
  final String? loadingText;
  final String? successText;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const LoadingStatus({
    super.key,
    required this.isLoading,
    required this.isSuccess,
    this.loadingText,
    this.successText,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  State<LoadingStatus> createState() => _LoadingStatusState();
}

class _LoadingStatusState extends State<LoadingStatus> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleScaleAnimation;
  late final Animation<double> _iconScaleAnimation;
  late final Animation<double> _rippleScaleAnimation;
  late final Animation<double> _rippleOpacityAnimation;
  late final Animation<double> _textFadeAnimation;
  late final Animation<double> _textSlideAnimation;
  late final Animation<double> _buttonFadeAnimation;
  late final Animation<double> _buttonSlideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 1. Success checkmark background circle scale (bouncy)
    _circleScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // 2. Ripple rings expand and fade out
    _rippleScaleAnimation = Tween<double>(begin: 0.8, end: 1.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
      ),
    );
    _rippleOpacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
      ),
    );

    // 3. Inner checkmark icon scale with elastic bouncy look
    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.65, curve: Curves.elasticOut),
      ),
    );

    // 4. Text fade-in and slide-up
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    _textSlideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    // 5. Button fade-in and slide-up
    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _buttonSlideAnimation = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    if (widget.isSuccess) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant LoadingStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSuccess && !oldWidget.isSuccess) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E6B63),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isLoading) ...[
                      const SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        widget.loadingText ?? 'loading'.tr,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ) ??
                            const TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                      ),
                    ] else if (widget.isSuccess) ...[
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Concentric pulse/ripple rings
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _rippleOpacityAnimation.value,
                                child: Transform.scale(
                                  scale: _rippleScaleAnimation.value,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.35),
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _rippleOpacityAnimation.value * 0.6,
                                child: Transform.scale(
                                  scale: _rippleScaleAnimation.value * 1.3,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Bouncy Background Circle
                          ScaleTransition(
                            scale: _circleScaleAnimation,
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ScaleTransition(
                                scale: _iconScaleAnimation,
                                child: RotationTransition(
                                  turns: Tween<double>(begin: -0.05, end: 0.0).animate(_iconScaleAnimation),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF0E6B63),
                                    size: 52,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Animated Text
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textFadeAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0.0, _textSlideAnimation.value),
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            widget.successText ?? 'updated_successfully'.tr,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  height: 1.4,
                                ) ??
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.isSuccess && widget.onButtonPressed != null)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _buttonFadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0.0, _buttonSlideAnimation.value),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onButtonPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0E6B63),
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        widget.buttonText ?? 'continue'.tr,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: const Color(0xFF0E6B63),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ) ??
                            const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
