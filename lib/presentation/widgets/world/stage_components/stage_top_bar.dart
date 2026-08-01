import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';

/// The top bar for a stage page showing the user's shop avatar, a progress
/// indicator with dots/stars, and an action button.
class StageTopBar extends StatelessWidget {
  const StageTopBar({
    super.key,
    required this.totalExercises,
    required this.completedExercises,
    required this.exerciseDotStates,
    required this.onActionTap,
    this.actionIcon = Icons.pause,
    this.avatarWidget,
  });

  /// Total number of exercises in this stage.
  final int totalExercises;

  /// Number of exercises completed so far.
  final int completedExercises;

  /// Per-exercise dot state list.
  final List<StarState> exerciseDotStates;

  /// Called when the action button is tapped.
  final VoidCallback onActionTap;

  /// Icon displayed on the action button.
  final IconData actionIcon;

  /// Custom avatar widget to display instead of the default shop avatar.
  final Widget? avatarWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
      child: Row(
        children: [
          // Left User Shop Avatar Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: avatarWidget ?? _buildDefaultAvatar(),
            ),
          ),
          const SizedBox(width: 10),

          // Center White Pill Progress Bar
          Expanded(
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: LayoutBuilder(
                  builder: (context, cst) {
                    final w = cst.maxWidth;
                    final h = cst.maxHeight;

                    final spacing = totalExercises > 0 ? (w / totalExercises) : w;
                    final dotSize = (spacing * 0.5).clamp(8.0, 16.0);
                    final starSize = (dotSize * 2.2).clamp(20.0, 36.0);
                    final barHeight = (dotSize * 0.6).clamp(6.0, 10.0);

                    final barTop = (h - barHeight) / 2;
                    final dotTop = barTop + (barHeight / 2) - (dotSize / 2);
                    final starTop = barTop + (barHeight / 2) - (starSize / 2);

                    final reqs = _getStarRequirementIndices(totalExercises);
                    final starPositions = _getStarPositions(
                      totalExercises,
                      completedExercises,
                      exerciseDotStates,
                      reqs,
                    );

                    final positions = <double>[];
                    if (totalExercises > 0) {
                      for (int i = 0; i < totalExercises; i++) {
                        final t = (i + 0.5) / totalExercises;
                        positions.add(t * w);
                      }
                    }

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (int i = 0; i < totalExercises; i++)
                          () {
                            final isStar = starPositions.contains(i);
                            final state = i < exerciseDotStates.length
                                ? exerciseDotStates[i]
                                : StarState.pending;

                            if (isStar && state != StarState.wrong) {
                              final asset = state == StarState.correct
                                  ? 'assets/animated/star.json'
                                  : 'assets/animated/star_border.json';

                              return Positioned(
                                left: (positions[i] - starSize / 2).clamp(
                                  0.0,
                                  w - starSize,
                                ),
                                top: starTop,
                                child: SizedBox(
                                  width: starSize,
                                  height: starSize,
                                  child: Lottie.asset(
                                    asset,
                                    repeat: false,
                                    animate: state == StarState.correct,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            }

                            Color fill;
                            Color border;
                            switch (state) {
                              case StarState.correct:
                                fill = AppColors.buttonPrimary;
                                border = Colors.white;
                                break;
                              case StarState.wrong:
                                fill = Colors.redAccent;
                                border = Colors.white;
                                break;
                              default:
                                fill = Colors.grey.shade300;
                                border = Colors.grey.shade400;
                            }

                            return Positioned(
                              left: (positions[i] - dotSize / 2).clamp(
                                0.0,
                                w - dotSize,
                              ),
                              top: dotTop,
                              child: Container(
                                width: dotSize,
                                height: dotSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: fill,
                                  border: Border.all(color: border, width: 2),
                                ),
                              ),
                            );
                          }(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Right Teal Action / Pause Button
          GestureDetector(
            onTap: onActionTap,
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
              child: Icon(
                actionIcon,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<int> _getStarRequirementIndices(int total) {
    final reqs = <int>[];
    if (total >= 3) {
      reqs.add((total / 3).ceil());
      reqs.add((total * 2 / 3).ceil());
      reqs.add(total);
    } else {
      for (int i = 1; i <= total; i++) {
        reqs.add(i);
      }
    }
    return reqs;
  }

  Set<int> _getStarPositions(
    int total,
    int completed,
    List<StarState> states,
    List<int> reqs,
  ) {
    int correctCount = 0;
    final starPositions = <int>{};

    for (int i = 0; i < completed; i++) {
      if (i < states.length && states[i] == StarState.correct) {
        correctCount++;
        if (reqs.contains(correctCount)) {
          starPositions.add(i);
        }
      }
    }

    for (final r in reqs) {
      if (r > correctCount) {
        final needed = r - correctCount;
        final pos = completed + needed - 1;
        if (pos < total) {
          starPositions.add(pos);
        }
      }
    }
    return starPositions;
  }

  Widget _buildDefaultAvatar() {
    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      final ShopAvatar? shopAvatar = homeController.currentShopAvatar;

      if (shopAvatar != null && shopAvatar.assetPath != null && shopAvatar.assetPath!.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.all(2),
          child: Image.asset(
            shopAvatar.assetPath!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              shopAvatar.icon ?? Icons.person,
              size: 28,
              color: const Color(0xFF2B7A6B),
            ),
          ),
        );
      } else if (shopAvatar?.icon != null) {
        return Icon(
          shopAvatar!.icon,
          size: 28,
          color: const Color(0xFF2B7A6B),
        );
      }
    }

    return const Icon(
      Icons.person,
      size: 28,
      color: Color(0xFF2B7A6B),
    );
  }
}
