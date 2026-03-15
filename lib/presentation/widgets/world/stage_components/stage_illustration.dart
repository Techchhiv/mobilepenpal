import 'package:flutter/material.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';

/// Displays the character illustration (image or digit-grid) for the current
/// exercise, along with an optional label underneath.
///
/// Passive widget: No internal Obx. Caller must manage reactivity.
class StageIllustration extends StatelessWidget {
  const StageIllustration({
    super.key,
    required this.illustrationAssetPath,
    required this.illustrationLabel,
    required this.selectedCharacter,
    this.mathPromptWidget,
  });

  final String illustrationAssetPath;
  final String illustrationLabel;
  final String selectedCharacter;

  /// Optional widget to render instead of the normal illustration.
  final Widget? mathPromptWidget;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: mathPromptWidget ?? _buildMainIllustration(),
          ),

          // Label (below image, hidden for digits or if math prompt is used)
          if (mathPromptWidget == null && _shouldShowLabel())
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                illustrationLabel,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainIllustration() {
    final digit = NumberFormatUtils.parseSingleDigitAny(selectedCharacter);

    if (digit != null) {
      return _buildDigitGrid(illustrationAssetPath, digit);
    }

    return _buildSingleImage(illustrationAssetPath);
  }

  bool _shouldShowLabel() {
    if (illustrationLabel.isEmpty) return false;
    final digit = NumberFormatUtils.parseSingleDigitAny(selectedCharacter);
    return digit == null;
  }

  // ─── Digit grid (for numbers like ១–៩) ───────────────────────────────

  Widget _buildDigitGrid(String path, int digit) {
    final count = digit == 0 ? 1 : digit;
    double itemSize = count <= 4 ? 64 : 52;
    final spacing = count > 5 ? 6.0 : 8.0;

    final List<int> row1;
    final List<int> row2;

    if (count <= 5) {
      row1 = List.generate(count, (i) => i);
      row2 = const [];
    } else {
      final firstRowCount = (count / 2).ceil();
      row1 = List.generate(firstRowCount, (i) => i);
      row2 = List.generate(count - firstRowCount, (i) => i);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _digitRow(row1, path, itemSize, spacing),
          if (row2.isNotEmpty) ...[
            const SizedBox(height: 6),
            _digitRow(row2, path, itemSize, spacing),
          ],
        ],
      ),
    );
  }

  Widget _digitRow(
    List<int> indices,
    String path,
    double itemSize,
    double spacing,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: indices
          .map(
            (_) => Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: SizedBox(
                width: itemSize,
                height: itemSize,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: path.isEmpty
                      ? const SizedBox.shrink()
                      : Image.asset(
                          path,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey.shade300,
                          ),
                        ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ─── Single illustration image (for consonants etc.) ──────────────────

  Widget _buildSingleImage(String path) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: path.isEmpty
              ? const SizedBox.shrink()
              : Image.asset(
                  path,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.image_not_supported_outlined,
                    size: 44,
                    color: Colors.grey.shade600,
                  ),
                ),
        ),
      ),
    );
  }
}
