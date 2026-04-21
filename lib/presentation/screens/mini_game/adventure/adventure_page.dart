import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class AdventurePage extends StatefulWidget {
  const AdventurePage({super.key});

  @override
  State<AdventurePage> createState() => _AdventurePageState();
}

class _AdventurePageState extends State<AdventurePage>
    with TickerProviderStateMixin {
  final GetStorage _box = GetStorage();
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C5364), AppColors.textGray80],
          ),
        ),
        child: Stack(
          children: [
            // Main content
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Env.globalMaxWidth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildTopBar(),
                        const Spacer(flex: 2),
                        _buildTitle(),
                        const SizedBox(height: 32),
                        _buildHighScoreCard(),
                        const SizedBox(height: 40),
                        _buildPlayButton(),
                        const Spacer(flex: 3),
                        _buildStatsRow(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        // Back Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Avatar
        _buildAvatarCircle(),
        const SizedBox(width: 12),
        // Player name
        Expanded(
          child: Builder(
            builder: (_) {
              if (!Get.isRegistered<HomeController>()) {
                return const SizedBox.shrink();
              }
              final home = Get.find<HomeController>();
              return Obx(
                () => Text(
                  home.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ),
        // Coin balance
        _buildCoinChip(),
      ],
    );
  }

  Widget _buildAvatarCircle() {
    Widget avatarContent = const Icon(
      Icons.person,
      size: 26,
      color: Colors.white70,
    );
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      final shopAvatar = home.currentShopAvatar;
      if (shopAvatar != null && shopAvatar.id != 'default') {
        if (shopAvatar.assetPath != null) {
          avatarContent = Padding(
            padding: const EdgeInsets.all(6),
            child: Image.asset(shopAvatar.assetPath!, fit: BoxFit.contain),
          );
        } else {
          avatarContent = Icon(
            shopAvatar.icon ?? Icons.person,
            size: 26,
            color: Colors.white,
          );
        }
      }
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
      child: ClipOval(child: avatarContent),
    );
  }

  Widget _buildCoinChip() {
    if (!Get.isRegistered<ShopController>()) return const SizedBox.shrink();
    final shop = Get.find<ShopController>();

    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.circle, color: Colors.yellow.shade700, size: 18),
                const Icon(Icons.attach_money, color: Colors.white, size: 12),
              ],
            ),
            const SizedBox(width: 6),
            Text(
              NumberFormatUtils.intText(shop.totalPoints.value),
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
            ),
          ),
          child: const Icon(Icons.draw_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4), Color(0xFFFFD700)],
          ).createShader(bounds),
          child: const Text(
            'DRAWING SPRINT',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 3,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighScoreCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) {
              final glow = 0.5 + _glowCtrl.value * 0.5;
              return Icon(
                Icons.emoji_events_rounded,
                color: const Color(0xFFFFD700).withValues(alpha: glow),
                size: 28,
              );
            },
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BEST SCORE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.45),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_box.read<int>('sprint_high_score') ?? 0}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFD700),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return Container(
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _onPlay,
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: Ink(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final bestCombo = _box.read<int>('sprint_best_combo') ?? 0;
    final gamesPlayed = _box.read<int>('sprint_games_played') ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFF6B6B),
          label: 'Best Combo',
          value: '$bestCombo',
        ),
        _buildStatItem(
          icon: Icons.timer_rounded,
          color: const Color(0xFF4ECDC4),
          label: 'Games Played',
          value: '$gamesPlayed',
        ),
        _buildStatItem(
          icon: Icons.star_rounded,
          color: const Color(0xFFFFD700),
          label: 'High Score',
          value: '${_box.read<int>('sprint_high_score') ?? 0}',
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _onPlay() async {
    // Navigate to the AdventureStagePage (game)
    await Get.toNamed(AppRoutes.adventureStage);
    if (mounted) {
      setState(() {});
    }
  }
}
