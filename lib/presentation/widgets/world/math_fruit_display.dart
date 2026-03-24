import 'dart:math';
import 'package:flutter/material.dart';

/// Renders a math prompt (e.g. "2 + 3 = ?") using fruit images for numbers
/// and styled text for operators / question marks.
///
/// Each integer token is displayed as a row of fruit images (apple by default).
/// Operators (+, -, ×, ÷, =) and the question mark are rendered as text.
class MathFruitDisplay extends StatelessWidget {
  const MathFruitDisplay({
    super.key,
    required this.prompt,
    this.fruitSize = 48.0,
  });

  final String prompt;

  final double fruitSize;

  static const List<String> _fruitAssets = [
    'assets/images/digits/apple.png',
    'assets/images/digits/green_apple.png',
    'assets/images/digits/orange.png',
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = prompt.trim().split(RegExp(r'\s+'));

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20.0),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _buildTokenWidgets(tokens),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTokenWidgets(List<String> tokens) {
    final widgets = <Widget>[];

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      final cleaned = token.replaceAll(RegExp(r'[()]'), '');
      final number = int.tryParse(cleaned);

      if (number != null && number > 0) {
        // Use a stable but "random" fruit for this specific token position
        // so left and right can be different.
        final seed = prompt.hashCode ^ i;
        final fruitPath =
            _fruitAssets[Random(seed).nextInt(_fruitAssets.length)];
        widgets.add(_buildFruitGroup(number, fruitPath));
      } else {
        // Operator, '?', '=', or other text token
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              token,
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildFruitGroup(int count, String fruitPath) {
    // For counts <= 5, single row. For > 5, split into two rows.
    if (count <= 5) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            count,
            (_) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: _fruitImage(fruitPath),
            ),
          ),
        ),
      );
    }

    final firstRowCount = (count / 2).ceil();
    final secondRowCount = count - firstRowCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              firstRowCount,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: _fruitImage(fruitPath),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              secondRowCount,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: _fruitImage(fruitPath),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fruitImage(String fruitPath) {
    return SizedBox(
      width: fruitSize,
      height: fruitSize,
      child: Image.asset(
        fruitPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: fruitSize * 0.8,
          height: fruitSize * 0.8,
          decoration: const BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
