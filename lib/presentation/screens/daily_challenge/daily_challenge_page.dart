import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/daily_challenge/daily_challenge_controller.dart';

class DailyChallengePage extends StatelessWidget {
  final DailyChallengeController controller = Get.find<DailyChallengeController>();

  DailyChallengePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bolt_rounded,
            size: 80,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Daily Challenge',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        
        ],
      ),
    );
  }
}
