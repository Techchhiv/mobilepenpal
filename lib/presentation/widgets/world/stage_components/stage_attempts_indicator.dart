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
    if (attemptLeft >= maxAttempts) {
      return const SizedBox.shrink();
    }

    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(maxAttempts, (index) {
          final isFilled = index < attemptLeft;
          return Padding(
            padding: const EdgeInsets.only(left: 2.0),
            child: Icon(
              isFilled ? Icons.favorite : Icons.favorite_border,
              color: Colors.redAccent,
              size: 26,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          );
        }),
      );
  }
}
