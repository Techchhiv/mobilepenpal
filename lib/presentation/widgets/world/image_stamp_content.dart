import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:flutter_drawing_board/paint_extension.dart';

/// A custom [PaintContent] that stamps a rotated image along the user's stroke
/// path instead of drawing a plain line.
///
/// The image is drawn at fixed intervals ([spacing]) along the accumulated
/// path.  Each stamp is rotated so that the image "faces" the direction
/// the user is drawing (tangent angle between consecutive points).
///
/// Falls back gracefully: if [stampImage] is null, it paints a simple circle
/// dot at each stamp position.
class ImageStampContent extends PaintContent {
  ImageStampContent({
    this.stampImage,
    this.stampSize = 28.0,
    this.spacing = 32.0,
  });

  /// The image to stamp along the stroke.
  final ui.Image? stampImage;

  /// Width & height of each stamped image (in logical pixels).
  final double stampSize;

  /// Minimum distance between successive stamps (in logical pixels).
  final double spacing;

  /// Collected touch points.
  final List<Offset> _points = [];

  /// Running arc-length at each point (parallel to [_points]).
  final List<double> _cumLen = [0.0];

  @override
  void startDraw(Offset startPoint) {
    _points.clear();
    _cumLen
      ..clear()
      ..add(0.0);
    _points.add(startPoint);
  }

  @override
  void drawing(Offset nowPoint) {
    if (_points.isEmpty) {
      startDraw(nowPoint);
      return;
    }

    final prev = _points.last;
    final d = (nowPoint - prev).distance;
    if (d < 1.5) return;

    _points.add(nowPoint);
    _cumLen.add(_cumLen.last + d);
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (_points.length < 2) {
      if (_points.isNotEmpty) {
        _drawStampAt(canvas, _points.first, 0.0);
      }
      return;
    }

    final totalLen = _cumLen.last;
    if (totalLen <= 0) return;

    double nextStampAt = 0.0;
    int seg = 1;

    while (nextStampAt <= totalLen && seg < _points.length) {
      while (seg < _points.length - 1 && _cumLen[seg] < nextStampAt) {
        seg++;
      }

      final segStart = _cumLen[seg - 1];
      final segEnd = _cumLen[seg];
      final segLen = segEnd - segStart;

      Offset pos;
      double angle;

      if (segLen <= 0) {
        pos = _points[seg];
        angle = 0.0;
      } else {
        final t = ((nextStampAt - segStart) / segLen).clamp(0.0, 1.0);
        final a = _points[seg - 1];
        final b = _points[seg];
        pos = Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
        angle = atan2(b.dy - a.dy, b.dx - a.dx);
      }

      _drawStampAt(canvas, pos, angle);
      nextStampAt += spacing;
    }
  }

  void _drawStampAt(Canvas canvas, Offset center, double angle) {
    final img = stampImage;
    if (img == null) {
      canvas.drawCircle(
        center,
        stampSize / 4,
        Paint()
          ..color = paint.color
          ..style = PaintingStyle.fill,
      );
      return;
    }

    final half = stampSize / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final src = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    final dst = Rect.fromLTWH(-half, -half, stampSize, stampSize);

    canvas.drawImageRect(
      img,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  // ── Copy / serialization ──

  @override
  ImageStampContent copy() => ImageStampContent(
    stampImage: stampImage,
    stampSize: stampSize,
    spacing: spacing,
  );

  @override
  String get contentType => 'ImageStampContent';

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'stampSize': stampSize,
      'spacing': spacing,
      'points': _points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'paint': paint.toJson(),
    };
  }
}
