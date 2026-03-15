import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';

/// The top bar for a stage page showing a pencil avatar, a progress
/// indicator with dots/stars, and an action button.
///
/// Passive widget: No internal Obx. Caller must manage reactivity.
class StageTopBar extends StatelessWidget {
  const StageTopBar({
    super.key,
    required this.totalExercises,
    required this.completedExercises,
    required this.exerciseDotStates,
    required this.onActionTap,
    this.actionIcon = Icons.pause,
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
      child: Row(
        children: [
          // Pencil avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/illustrations/pencil.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),

          // Progress indicator
          Expanded(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: LayoutBuilder(
                  builder: (context, cst) {
                    final w = cst.maxWidth;
                    final h = cst.maxHeight;

                    // Calculate dynamic sizes based on available width and exercise count
                    final spacing = totalExercises > 0 ? (w / totalExercises) : w;
                    
                    // Aim for dots to take up about 50% of their allotted space, capped at 18
                    final dotSize = (spacing * 0.5).clamp(8.0, 18.0);
                    // Stars are roughly 2x the dot size, capped at 40
                    final starSize = (dotSize * 2.2).clamp(20.0, 40.0);
                    // Bar height scales with dots
                    final barHeight = (dotSize * 0.6).clamp(6.0, 12.0);

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

          const SizedBox(width: 12),

          // Action button
          GestureDetector(
            onTap: onActionTap,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white60,
                shape: BoxShape.circle,
              ),
              child: Icon(
                actionIcon,
                color: AppColors.buttonPrimary,
                size: 28,
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
}
