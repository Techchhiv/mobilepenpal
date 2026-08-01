import 'package:flutter/material.dart';

/// Reusable floating action buttons for stage exercise screens.
/// Features a circular Red Delete/Clear button and a circular Teal Skip/Next button.
class StageFloatingActionButtons extends StatelessWidget {
  const StageFloatingActionButtons({
    super.key,
    required this.onClear,
    required this.onSubmitOrSkip,
    this.isSubmitting = false,
    this.submitIcon = Icons.skip_next_rounded,
  });

  /// Called when the delete/clear button is tapped.
  final VoidCallback onClear;

  /// Called when the submit/skip button is tapped.
  final VoidCallback onSubmitOrSkip;

  /// Whether a submission is currently loading/processing.
  final bool isSubmitting;

  /// Icon to show on the primary action button (default: skip next).
  final IconData submitIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Clear / Trash Button (Red)
        GestureDetector(
          onTap: onClear,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Skip / Submit Button (Teal)
        GestureDetector(
          onTap: isSubmitting ? null : onSubmitOrSkip,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF2B7A6B),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2B7A6B).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isSubmitting
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Icon(
                    submitIcon,
                    color: Colors.white,
                    size: 28,
                  ),
          ),
        ),
      ],
    );
  }
}
