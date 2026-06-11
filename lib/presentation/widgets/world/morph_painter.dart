import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class MorphPainter extends CustomPainter {
  // ── Morph Configuration Defaults ──────────────────────────────────
  static const Duration defaultDuration = Duration(milliseconds: 400);
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Color defaultFromColor = Color(0xFF2B7A78);
  static const Color defaultToColor = Color(0xFF2B7A78);
  static const double defaultStrokeWidth = 8.0;
  static const double defaultGlowBlur = 8.0;
  static const double defaultGlowOpacity = 0.25;

  MorphPainter({
    required this.userStrokes,
    required this.templateStrokes,
    required this.progress,
    this.fromColor = defaultFromColor,
    this.toColor = defaultToColor,
    this.strokeWidth = defaultStrokeWidth,
    this.curve = defaultCurve,
    this.glowBlur = defaultGlowBlur,
    this.glowOpacity = defaultGlowOpacity,
    this.stampImage,
    this.stampSize = 24.0,
    this.spacing = 16.0,
  });

  final List<List<Offset>> userStrokes;
  final List<List<Offset>> templateStrokes;
  final double progress;
  final Color fromColor;
  final Color toColor;
  final double strokeWidth;
  final Curve curve;
  final double glowBlur;
  final double glowOpacity;
  final ui.Image? stampImage;
  final double stampSize;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    if (userStrokes.isEmpty || templateStrokes.isEmpty) return;

    final count = userStrokes.length;

    // Eased progress for a more organic feel.
    final t = curve.transform(progress.clamp(0.0, 1.0));

    final lerpedColor = Color.lerp(fromColor, toColor, t)!;

    // Glow paint (drawn behind the main stroke).
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur)
      ..color = toColor.withValues(alpha: glowOpacity * t);

    // Main stroke paint.
    final mainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = lerpedColor;

    for (int s = 0; s < count; s++) {
      final uStroke = userStrokes[s];
      final tStroke = s < templateStrokes.length
          ? templateStrokes[s]
          : templateStrokes.last;

      final ptCount = uStroke.length;
      if (ptCount < 2) continue;

      final morphedPoints = <Offset>[];
      for (int i = 0; i < ptCount; i++) {
        final u = uStroke[i];
        final tIdx = i < tStroke.length ? i : tStroke.length - 1;
        final tp = tStroke[tIdx];

        final x = ui.lerpDouble(u.dx, tp.dx, t)!;
        final y = ui.lerpDouble(u.dy, tp.dy, t)!;
        morphedPoints.add(Offset(x, y));
      }

      if (stampImage != null) {
        // Draw stamps along morphedPoints
        final cumLen = <double>[0.0];
        for (int i = 1; i < morphedPoints.length; i++) {
          cumLen.add(cumLen.last + (morphedPoints[i] - morphedPoints[i - 1]).distance);
        }
        final totalLen = cumLen.last;
        if (totalLen <= 0) continue;

        double nextStampAt = 0.0;
        int seg = 1;

        while (nextStampAt <= totalLen && seg < morphedPoints.length) {
          while (seg < morphedPoints.length - 1 && cumLen[seg] < nextStampAt) {
            seg++;
          }

          final segStart = cumLen[seg - 1];
          final segEnd = cumLen[seg];
          final segLen = segEnd - segStart;

          Offset pos;
          double angle;

          if (segLen <= 0) {
            pos = morphedPoints[seg];
            angle = 0.0;
          } else {
            final tSeg = ((nextStampAt - segStart) / segLen).clamp(0.0, 1.0);
            final a = morphedPoints[seg - 1];
            final b = morphedPoints[seg];
            pos = Offset(a.dx + (b.dx - a.dx) * tSeg, a.dy + (b.dy - a.dy) * tSeg);
            angle = ui.lerpDouble(0.0, atan2(b.dy - a.dy, b.dx - a.dx), 1.0)!;
          }

          _drawStampAt(canvas, stampImage!, pos, angle, stampSize);
          nextStampAt += spacing;
        }
      } else {
        // Draw standard line path
        final path = Path();
        bool moved = false;
        for (final pt in morphedPoints) {
          if (!moved) {
            path.moveTo(pt.dx, pt.dy);
            moved = true;
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        }
        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, mainPaint);
      }
    }
  }

  void _drawStampAt(
    Canvas canvas,
    ui.Image img,
    Offset center,
    double angle,
    double size,
  ) {
    final half = size / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final src = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    final dst = Rect.fromLTWH(-half, -half, size, size);

    canvas.drawImageRect(
      img,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MorphPainter old) {
    return old.progress != progress ||
        old.userStrokes != userStrokes ||
        old.templateStrokes != templateStrokes ||
        old.fromColor != fromColor ||
        old.toColor != toColor ||
        old.strokeWidth != strokeWidth ||
        old.curve != curve ||
        old.glowBlur != glowBlur ||
        old.glowOpacity != glowOpacity ||
        old.stampImage != stampImage ||
        old.stampSize != stampSize ||
        old.spacing != spacing;
  }
}
