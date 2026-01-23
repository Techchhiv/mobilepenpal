import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobilepenpal/data/models/world/world_level.dart';

class LevelCircle extends StatelessWidget {
  final WorldLevel level;
  final bool isCurrent;
  final Future<void> Function(WorldLevel) onTap;

  const LevelCircle({
    super.key,
    required this.level,
    required this.onTap,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnlocked = level.isUnlocked == 1 || level.isUnlocked == true;
    final double progress = (level.completionPercentage / 100.0).clamp(0.0, 1.0);
    final bool isCompleted = progress >= 1.0;

    const double ring = 72;
    const double core = 56;
    const double halo = 86;

    final Color progressColor = Colors.blue.shade600;

    return SizedBox(
      width: ring,
      height: ring,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -52,
            child: _FloatingCard(
              text: level.name,
              isCurrent: isCurrent,
              isUnlocked: isUnlocked,
            ),
          ),

          if (isCurrent && isUnlocked) const _CleanHalo(size: halo),

          SizedBox(
            width: ring,
            height: ring,
            child: CircularProgressIndicator(
              value: isUnlocked ? progress : 0.0,
              strokeWidth: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.85),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),

          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: Ink(
              width: core,
              height: core,
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.white : Colors.grey.shade400,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade600, width: 3),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onTap(level),
                child: Center(
                  child: isUnlocked
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${level.orderIndex}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                height: 1.0,
                                color: Colors.black,
                              ),
                            ),
                            if (isCurrent && !isCompleted)
                              Icon(
                                Icons.play_arrow_rounded,
                                size: 18,
                                color: Colors.green.shade600,
                              )
                            else if (isCompleted)
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.orange.shade600,
                              ),
                          ],
                        )
                      : const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ),
          ),

          if (isCompleted)
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
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _CleanHalo extends StatelessWidget {
  final double size;
  const _CleanHalo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withValues(alpha: 0.35),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.yellow.shade400, width: 4),
          ),
        ),
      ],
    );
  }
}

class _FloatingCard extends StatelessWidget {
  final String text;
  final bool isCurrent;
  final bool isUnlocked;

  const _FloatingCard({
    required this.text,
    required this.isCurrent,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Colors.white;
    final borderColor = isCurrent
        ? Colors.yellow.shade700
        : Colors.black.withValues(alpha: 0.10);

    final fg = isUnlocked ? Colors.black : Colors.black.withValues(alpha: 0.65);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
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
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(18, 10),
          painter: _TrianglePainter(color: bg),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
