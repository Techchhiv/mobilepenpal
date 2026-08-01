import 'package:flutter/material.dart';

/// A reusable top variant bar that displays character variations (e.g., ឆ, ឆា, ឆិ, ឆី)
/// in a single horizontal scrollable row inside a centered white pill bar, alongside a circular teal audio button.
class StageVariantBar extends StatefulWidget {
  const StageVariantBar({
    super.key,
    required this.variants,
    required this.currentIndex,
    required this.onVariantSelected,
    required this.onSpeakerTap,
    this.showSelectionHighlight = false,
  });

  /// List of character strings to display (e.g., ['ឆ', 'ឆា', 'ឆិ', 'ឆី']).
  final List<String> variants;

  /// Index of the currently active variant.
  final int currentIndex;

  /// Callback when a variant is selected by tapping.
  final ValueChanged<int> onVariantSelected;

  /// Callback when the speaker button is tapped.
  final VoidCallback onSpeakerTap;

  /// Whether to draw the orange/yellow selection border & highlight around active variant.
  final bool showSelectionHighlight;

  @override
  State<StageVariantBar> createState() => _StageVariantBarState();
}

class _StageVariantBarState extends State<StageVariantBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant StageVariantBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _scrollToIndex(widget.currentIndex);
    }
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients || widget.variants.isEmpty) return;
    const itemEstimatedWidth = 50.0;
    final targetOffset = (index * itemEstimatedWidth) - 70.0;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 4),
      child: Row(
        children: [
          // Left Spacer matching top avatar width for exact centered alignment
          const SizedBox(width: 62),

          // Center Variant Pill (Single Horizontal Scrollable Row)
          if (widget.variants.isNotEmpty)
            Expanded(
              child: Center(
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(widget.variants.length, (index) {
                        final isSelected = widget.showSelectionHighlight && (index == widget.currentIndex);
                        return GestureDetector(
                          onTap: () {
                            widget.onVariantSelected(index);
                            _scrollToIndex(index);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFF9F43).withValues(alpha: 0.18)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              border: isSelected
                                  ? Border.all(
                                      color: const Color(0xFFFF9F43),
                                      width: 1.8,
                                    )
                                  : null,
                            ),
                            child: Text(
                              widget.variants[index],
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? const Color(0xFFFF9F43)
                                    : const Color(0xFF4A4A4A),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),

          if (widget.variants.isNotEmpty) const SizedBox(width: 10),

          // Circular Sound Speaker Button (Aligned directly under top Pause button)
          GestureDetector(
            onTap: widget.onSpeakerTap,
            child: Container(
              width: 52,
              height: 52,
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
              child: const Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
