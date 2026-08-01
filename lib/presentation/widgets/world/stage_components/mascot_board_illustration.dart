import 'package:flutter/material.dart';

/// A mascot board widget that displays the cute mascot figure holding a whiteboard frame
/// (`assets/images/decorations/model_writting.png`), with the current exercise's dynamic
/// illustration / image widget framed inside the whiteboard area.
class MascotBoardIllustration extends StatelessWidget {
  const MascotBoardIllustration({
    super.key,
    required this.illustrationWidget,
    this.height = 230,
    this.scale = 1.2,
    this.boardTopRatio = 0.67,
    this.boardLeftRatio = -0.05,
    this.boardWidthRatio = 0.72,
    this.boardHeightRatio = 0.25,
    this.boardPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  /// The dynamic illustration widget to render inside the whiteboard frame.
  final Widget illustrationWidget;

  /// Base height of the mascot board widget.
  final double height;

  /// Scale multiplier for the entire mascot widget (1.0 = normal, 1.2 = 20% larger, 0.8 = 20% smaller).
  final double scale;

  /// Top position ratio relative to total height.
  final double boardTopRatio;

  /// Left position ratio relative to total height.
  final double boardLeftRatio;

  /// Width ratio of the board inner cutout relative to total height.
  final double boardWidthRatio;

  /// Height ratio of the board inner cutout relative to total height.
  final double boardHeightRatio;

  /// Inner padding inside the whiteboard cutout area.
  final EdgeInsetsGeometry boardPadding;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height * scale;

    return SizedBox(
      height: effectiveHeight,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            // Inner content framed inside the whiteboard (behind the frame cutout)
            Positioned(
              top: effectiveHeight * boardTopRatio,
              left: effectiveHeight * boardLeftRatio,
              width: effectiveHeight * boardWidthRatio,
              height: effectiveHeight * boardHeightRatio,
              child: Container(
                padding: boardPadding,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: illustrationWidget,
                  ),
                ),
              ),
            ),

            // Foreground mascot figure holding the frame, aligned to the bottom-left
            Positioned.fill(
              child: Image.asset(
                'assets/images/decorations/model_writting.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomLeft,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
