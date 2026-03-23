import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/daily_challenge/daily_challenge_controller.dart';

class DailyChallengePage extends GetView<DailyChallengeController> {
  const DailyChallengePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAFBF7),
              Color(0xFFF4F9FF),
              Color(0xFFFFF8EE),
            ],
          ),
        ),
        child: Stack(
          children: [
            _bubble(
              top: -50,
              right: -20,
              size: 150,
              color: const Color(0x3335B8AA),
            ),
            _bubble(
              top: 190,
              left: -22,
              size: 96,
              color: const Color(0x24FFB15F),
            ),
            _bubble(
              bottom: 90,
              right: -18,
              size: 124,
              color: const Color(0x22FF7F6A),
            ),
            SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Env.globalMaxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                    child: Center(child: _buildProfileCard()),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1D8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Color(0xFFCC8A1E),
                ),
                SizedBox(width: 6),
                Text(
                  'Daily Star',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9A6A16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _buildAvatar(),
          const SizedBox(height: 16),
          Text(
            controller.studentName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.1,
              color: Color(0xFF1A2A3A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _subtitleText(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  color: const Color(0xFFFF8C6B),
                  icon: Icons.local_fire_department_rounded,
                  value: '${controller.dailyStreak}',
                  label: 'Streak',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  color: const Color(0xFF28A69A),
                  icon: Icons.auto_awesome_rounded,
                  value: '+${controller.earnedXp}',
                  label: 'XP',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildStartButton(),
        ],
      ),
    );
  }

  String _subtitleText() {
    if (controller.isLoading.value) {
      return 'Getting today\'s game ready';
    }
    if (controller.hasChallenge) {
      return '${controller.challengeExerciseCount} fun tries ready';
    }
    return 'More fun soon';
  }

  Widget _buildAvatar() {
    final avatar = controller.currentAvatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 132,
          height: 132,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2AB6A2), Color(0xFF5ED0C4)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2AB6A2).withValues(alpha: 0.26),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.16),
            ),
            child: avatar?.assetPath != null
                ? ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        avatar!.assetPath!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          avatar.icon ?? Icons.person,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                    ),
                  )
                : Icon(
                    avatar?.icon ?? Icons.person,
                    color: Colors.white,
                    size: 52,
                  ),
          ),
        ),
        Positioned(
          right: 2,
          bottom: 8,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC957),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.star_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required Color color,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textGray80,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    final busy = controller.isLoading.value || controller.isStarting.value;
    final enabled = controller.hasChallenge && !busy;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? controller.startDailyChallenge : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: enabled
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.45),
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              ),
            ] else ...[
              const Icon(Icons.play_arrow_rounded, size: 22),
            ],
            const SizedBox(width: 10),
            Text(
              busy
                  ? 'Getting Ready'
                  : enabled
                  ? 'Start Daily Challenge'
                  : 'Come Back Soon',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble({
    double? top,
    double? right,
    double? bottom,
    double? left,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color,
                blurRadius: 26,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
