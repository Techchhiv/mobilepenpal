import 'dart:math' as math;
import 'package:flutter/material.dart';

class RandomlyFloatingAsset extends StatefulWidget {
  final String assetPath;
  final double width;
  final double minTop;
  final double maxTop;
  final double? minLeft;
  final double? maxLeft;
  final double? minRight;
  final double? maxRight;
  final double? minBottom;
  final double? maxBottom;
  final int minDurationMs;
  final int maxDurationMs;

  const RandomlyFloatingAsset({
    super.key,
    required this.assetPath,
    required this.width,
    required this.minTop,
    required this.maxTop,
    this.minLeft,
    this.maxLeft,
    this.minRight,
    this.maxRight,
    this.minBottom,
    this.maxBottom,
    this.minDurationMs = 5000,
    this.maxDurationMs = 8000,
  });

  @override
  State<RandomlyFloatingAsset> createState() => _RandomlyFloatingAssetState();
}

class _RandomlyFloatingAssetState extends State<RandomlyFloatingAsset>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  final math.Random _rand = math.Random();

  late double _top;
  double? _left;
  double? _right;
  double? _bottom;

  @override
  void initState() {
    super.initState();
    _randomizePosition();

    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.minDurationMs +
            _rand.nextInt(widget.maxDurationMs - widget.minDurationMs),
      ),
    );

    _setupAnimation();

    // Start with a small random delay
    Future.delayed(Duration(milliseconds: _rand.nextInt(1500)), () {
      if (mounted) _ctrl.forward();
    });
  }

  void _randomizePosition() {
    _top = widget.minTop + _rand.nextDouble() * (widget.maxTop - widget.minTop);
    
    if (widget.minLeft != null && widget.maxLeft != null) {
      _left = widget.minLeft! + _rand.nextDouble() * (widget.maxLeft! - widget.minLeft!);
    } else {
      _left = null;
    }

    if (widget.minRight != null && widget.maxRight != null) {
      _right = widget.minRight! + _rand.nextDouble() * (widget.maxRight! - widget.minRight!);
    } else {
      _right = null;
    }

    if (widget.minBottom != null && widget.maxBottom != null) {
      _bottom = widget.minBottom! + _rand.nextDouble() * (widget.maxBottom! - widget.minBottom!);
    } else {
      _bottom = null;
    }
  }

  void _setupAnimation() {
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(_ctrl);

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;
        
        setState(() {
          _randomizePosition();
        });

        // Delay before restarting
        Future.delayed(Duration(milliseconds: 1000 + _rand.nextInt(2000)), () {
          if (mounted) {
            _ctrl.duration = Duration(
              milliseconds: widget.minDurationMs +
                  _rand.nextInt(widget.maxDurationMs - widget.minDurationMs),
            );
            _ctrl.forward(from: 0);
          }
        });
      }
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
      builder: (context, child) {
        // Floating offset logic
        final floatOffset = math.sin(_ctrl.value * math.pi * 2) * 15;
        // Wiggle rotation logic
        final rotation = math.sin(_ctrl.value * math.pi * 2) * 0.08;

        return Positioned(
          top: _top + floatOffset,
          left: _left,
          right: _right,
          bottom: _bottom != null ? _bottom! + floatOffset : null,
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.rotate(
              angle: rotation,
              child: Image.asset(
                widget.assetPath,
                width: widget.width,
              ),
            ),
          ),
        );
      },
    );
  }
}
