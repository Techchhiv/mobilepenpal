import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class MiniGamePage extends StatefulWidget {
  const MiniGamePage({super.key});

  @override
  State<MiniGamePage> createState() => _MiniGamePageState();
}

class _MiniGamePageState extends State<MiniGamePage>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Env.globalMaxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildTopBar(),
                  const SizedBox(height: 24),
                  _buildHeader(),
                  const SizedBox(height: 28),
                  Expanded(child: _buildGameGrid()),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Top bar with avatar and coins ──────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      children: [
        _buildAvatarCircle(),
        const SizedBox(width: 12),
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

  // ── Header ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _floatCtrl,
          builder: (_, child) {
            final dy = -4 * _floatCtrl.value;
            return Transform.translate(offset: Offset(0, dy), child: child);
          },
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE94560), Color(0xFFFF6B6B)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE94560).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFE94560), Color(0xFFFF6B6B), Color(0xFFFFD700)],
          ).createShader(bounds),
          child: const Text(
            'MINI GAMES',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a game to play!',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Game grid ──────────────────────────────────────────────────────
  Widget _buildGameGrid() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _buildGameCard(
          title: 'Drawing Sprint',
          subtitle: 'Draw characters against the clock!',
          icon: Icons.draw_rounded,
          gradientColors: const [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
          glowColor: const Color(0xFF4ECDC4),
          highScoreKey: 'sprint_high_score',
          onTap: () => Get.toNamed(AppRoutes.adventure),
        ),
        const SizedBox(height: 16),
        _buildComingSoonCard(
          title: 'Letter Match',
          subtitle: 'Match characters with their sounds',
          icon: Icons.hearing_rounded,
          gradientColors: const [Color(0xFFFF6B6B), Color(0xFFFFD93D)],
        ),
        const SizedBox(height: 16),
        _buildComingSoonCard(
          title: 'Memory Flip',
          subtitle: 'Flip cards and find matching pairs',
          icon: Icons.flip_rounded,
          gradientColors: const [Color(0xFF6BCB77), Color(0xFF4D96FF)],
        ),
      ],
    );
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required Color glowColor,
    required String highScoreKey,
    required VoidCallback onTap,
  }) {
    final box = GetStorage();
    final highScore = box.read<int>(highScoreKey) ?? 0;

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, child) {
        final glowOpacity = 0.15 + _pulseCtrl.value * 0.1;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: glowOpacity),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.1),
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.03),
                ],
              ),
              border: Border.all(
                color: gradientColors[0].withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Game icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (highScore > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.emoji_events_rounded,
                              color: const Color(0xFFFFD700),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Best: $highScore',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Arrow
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: gradientColors[0],
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Opacity(
      opacity: 0.45,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: Text(
                'SOON',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
