import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/mini_game/mini_game_hub_controller.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/data/models/mini_game/mini_game_model.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class MiniGamePage extends StatefulWidget {
  const MiniGamePage({super.key});

  @override
  State<MiniGamePage> createState() => _MiniGamePageState();
}

class _MiniGamePageState extends State<MiniGamePage>
    with TickerProviderStateMixin {
  final GetStorage _box = GetStorage();
  late final AnimationController _glowCtrl;
  final RxSet<int> _selectedGames = <int>{}.obs;
  final RxnString _selectedInputType = RxnString(null);

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Initialize selected games
    if (Get.isRegistered<MiniGameHubController>()) {
      final hubCtrl = Get.find<MiniGameHubController>();
      if (hubCtrl.miniGames.isNotEmpty) {
        _selectedGames.addAll(hubCtrl.miniGames.map((e) => e.id));
      }
      ever(hubCtrl.miniGames, (List<MiniGameModel> games) {
        if (_selectedGames.isEmpty && games.isNotEmpty) {
          _selectedGames.addAll(games.map((e) => e.id));
        }
      });
    }
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
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: Stack(
          children: [
            // Main content
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Env.globalMaxWidth,
                  ),
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
        const SizedBox(width: 8),
        // Settings icon
        _buildSettingsButton(),
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
              colors: [Color(0xFFE94560), Color(0xFFFF6B6B)],
            ),
          ),
          child: const Icon(
            Icons.sports_esports_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFE94560), Color(0xFFFF6B6B), Color(0xFFFFD700)],
          ).createShader(bounds),
          child: const Text(
            'MINI GAMES',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighScoreCard() {
    int maxHighScore = 0;
    if (Get.isRegistered<MiniGameHubController>()) {
      final games = Get.find<MiniGameHubController>().miniGames;
      for (var g in games) {
        final score =
            _box.read<int>('dynamic_minigame_${g.id}_high_score') ?? 0;
        if (score > maxHighScore) maxHighScore = score;
      }
    }

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
                '$maxHighScore',
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
          onTap: _showGameSelectionModal,
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: Ink(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE94560), Color(0xFFFF6B6B)],
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
    final gamesPlayed = _box.read<int>('dynamic_minigame_played_count') ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          icon: Icons.timer_rounded,
          color: const Color(0xFF4ECDC4),
          label: 'Games Played',
          value: '$gamesPlayed',
        ),
      ],
    );
  }

  Widget _buildSettingsButton() {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _showGameSelectionModal,
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 1.2,
            ),
          ),
          child: const Icon(
            Icons.settings_rounded,
            color: Colors.white70,
            size: 22,
          ),
        ),
      ),
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

  void _showGameSelectionModal() {
    final hubCtrl = Get.find<MiniGameHubController>();
    if (hubCtrl.miniGames.isEmpty) {
      Get.snackbar(
        'Oops!',
        'No mini-games available right now.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF16213E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF4ECDC4),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Game Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white54,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Choose which games and input mode to play.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              // ── Section: Mini Games ──
              _buildSectionLabel('MINI GAMES', Icons.sports_esports_rounded),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: hubCtrl.miniGames.length,
                  itemBuilder: (context, index) {
                    final game = hubCtrl.miniGames[index];
                    return Obx(() {
                      final isSelected = _selectedGames.contains(game.id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4ECDC4).withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4ECDC4).withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.08),
                            width: 1.5,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          activeColor: const Color(0xFF4ECDC4),
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          title: Text(
                            game.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            game.description ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 12,
                            ),
                          ),
                          onChanged: (val) {
                            if (val == true) {
                              _selectedGames.add(game.id);
                            } else {
                              _selectedGames.remove(game.id);
                            }
                          },
                        ),
                      );
                    });
                  },
                ),
              ),
              const SizedBox(height: 18),

              // ── Section: Input Type ──
              _buildSectionLabel('INPUT TYPE', Icons.gamepad_rounded),
              const SizedBox(height: 10),
              Obx(() {
                // Compute available input types across all selected games
                final selectedGamesList = hubCtrl.miniGames
                    .where((g) => _selectedGames.contains(g.id))
                    .toList();

                // Collect the union of compatible input types across all selected games
                final availableInputTypes = <String>{};
                for (final game in selectedGamesList) {
                  availableInputTypes.addAll(
                    game.compatibleInputTypes(game.displayType),
                  );
                }

                final inputOptions = availableInputTypes.toList();

                // If current selection is no longer available, reset to auto
                if (_selectedInputType.value != null &&
                    !inputOptions.contains(_selectedInputType.value)) {
                  _selectedInputType.value = null;
                }

                if (inputOptions.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Select at least one game to see input options.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // Build option chips: [Auto] + each available type
                final allOptions = <String?>[
                  null, // "Auto" option
                  ...inputOptions,
                ];

                return Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: allOptions.map((option) {
                    final isActive = _selectedInputType.value == option;
                    final label = _inputTypeLabel(option);
                    final icon = _inputTypeIcon(option);

                    return GestureDetector(
                      onTap: () => _selectedInputType.value = option,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF4ECDC4).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF4ECDC4)
                                : Colors.white.withValues(alpha: 0.12),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 18,
                              color: isActive
                                  ? const Color(0xFF4ECDC4)
                                  : Colors.white54,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFF4ECDC4)
                                    : Colors.white70,
                                fontSize: 13,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 24),

              // ── Start button ──
              Obx(
                () => ElevatedButton(
                  onPressed: _selectedGames.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          _startCustomRun();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    disabledBackgroundColor: Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'START RUN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  String _inputTypeLabel(String? type) {
    switch (type) {
      case 'drawing_board':
        return 'Drawing Board';
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'typing':
        return 'Typing';
      case null:
      default:
        return 'Auto (Random)';
    }
  }

  IconData _inputTypeIcon(String? type) {
    switch (type) {
      case 'drawing_board':
        return Icons.draw_rounded;
      case 'multiple_choice':
        return Icons.grid_view_rounded;
      case 'typing':
        return Icons.keyboard_rounded;
      case null:
      default:
        return Icons.shuffle_rounded;
    }
  }

  void _startCustomRun() {
    final hubCtrl = Get.find<MiniGameHubController>();
    final selectedGamesList = hubCtrl.miniGames
        .where((g) => _selectedGames.contains(g.id))
        .toList();

    if (selectedGamesList.isEmpty) return;

    // Increment played count
    final playedCount = _box.read<int>('dynamic_minigame_played_count') ?? 0;
    _box.write('dynamic_minigame_played_count', playedCount + 1);

    Get.toNamed(
      AppRoutes.dynamicMiniGame,
      arguments: {
        'miniGames': selectedGamesList,
        'inputType': _selectedInputType.value, // null = auto/random
      },
    );
  }
}
