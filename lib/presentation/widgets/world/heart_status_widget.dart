import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/world/heart_controller.dart';
import 'package:mobilepenpal/presentation/widgets/world/out_of_hearts_modal.dart';

class HeartStatusWidget extends StatelessWidget {
  const HeartStatusWidget({
    super.key,
    this.compact = false,
  });

  /// Compact view for tighter headers.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<HeartController>()) {
      Get.put(HeartController());
    }
    final heartController = HeartController.to;

    return Obx(() {
      final current = heartController.currentHearts.value;
      final isUnlimited = heartController.isUnlimited.value;
      final timerText = heartController.timeToNextHeartStr.value;

      if (isUnlimited) {
        return const SizedBox.shrink();
      }

      return GestureDetector(
        onTap: () {
          if (current <= 0 && !isUnlimited) {
            Get.dialog(const OutOfHeartsModal());
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: current <= 0 && !isUnlimited
                  ? Colors.redAccent
                  : const Color(0xFFFFCDD2),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFE53935),
                size: 22,
              ),
              const SizedBox(width: 6),

              // Heart Count text
              Text(
                isUnlimited
                    ? '∞'
                    : '$current/${HeartController.maxHearts}',
                style: TextStyle(
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.bold,
                  color: current <= 0 && !isUnlimited
                      ? const Color(0xFFD32F2F)
                      : const Color(0xFF2D3748),
                ),
              ),

              // Timer display when hearts are recovering
              if (!isUnlimited && current < HeartController.maxHearts && timerText.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 12,
                        color: Color(0xFFE65100),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        timerText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
