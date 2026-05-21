import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/config/env.dart';
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
  late final AnimationController _pulseCtrl;
  late final AnimationController _floatCtrl;
  final RxSet<int> _selectedGames = <int>{}.obs;
  final RxnString _selectedInputType = RxnString(null);
  final RxBool _isDetailView = false.obs;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
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
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/hub_cartoon_background.png',
              fit: BoxFit.cover,
            ),
          ),

          // Decorative Elements
          _buildDecorations(),

          // Main Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Env.globalMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildTopBar(),
                      const Spacer(flex: 1),
                      _buildLevelSign(),
                      const Spacer(flex: 2),
                      _buildCentralPlayArea(),
                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorations() {
    return Stack(
      children: const [
        _FloatingStar(
          initialTop: 200,
          initialLeft: 30,
          initialRight: 0,
          size: 70,
        ),
        _FloatingStar(
          initialTop: 450,
          initialLeft: 0,
          initialRight: 40,
          size: 90,
        ),
        _FloatingStar(
          initialTop: 100,
          initialLeft: 0,
          initialRight: 80,
          size: 50,
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        // Avatar and Player Name Chip
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildAvatarCircle(),
                const SizedBox(width: 10),
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
                            color: Color(0xFF4A4A4A),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
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
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF4ECDC4),
      ),
      child: ClipOval(child: avatarContent),
    );
  }

  Widget _buildCoinChip() {
    if (!Get.isRegistered<ShopController>()) return const SizedBox.shrink();
    final shop = Get.find<ShopController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, color: Colors.orange.shade400, size: 24),
          const SizedBox(width: 6),
          Obx(
            () => Text(
              NumberFormatUtils.intText(shop.totalPoints.value),
              style: const TextStyle(
                color: Color(0xFFE67E22),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSign() {
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9F43),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9F43).withValues(alpha: 0.5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'highest_score'.tr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: Get.locale?.languageCode == 'km' ? 0 : 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$maxHighScore',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralPlayArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The big play button
        GestureDetector(
          onTap: _showGameSelectionModal,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              final scale = 1.0 + (_pulseCtrl.value * 0.08);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4ECDC4),
                    border: Border.all(color: Colors.white, width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4ECDC4).withValues(alpha: 0.6),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 100,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showGameSelectionModal() {
    final hubCtrl = Get.find<MiniGameHubController>();
    if (hubCtrl.miniGames.isEmpty) {
      Get.snackbar(
        'oops'.tr,
        'no_mini_games_available_right_now'.tr,
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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9F43).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Color(0xFFFF9F43),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'choose_an_option'.tr,
                      style: const TextStyle(
                        color: Color(0xFF4A4A4A),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.black54,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // ── Section: Mini Games ──
              _buildSectionLabel(
                'choose_your_games'.tr,
                Icons.sports_esports_rounded,
                trailing: Obx(() {
                  final allSelected =
                      _selectedGames.length == hubCtrl.miniGames.length;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Select/Deselect All Button
                      GestureDetector(
                        onTap: () {
                          if (allSelected) {
                            _selectedGames.clear();
                          } else {
                            _selectedGames.addAll(
                              hubCtrl.miniGames.map((g) => g.id),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: allSelected
                                ? const Color(0xFFFF9F43).withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: allSelected
                                  ? const Color(0xFFFF9F43)
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                allSelected
                                    ? Icons.deselect_rounded
                                    : Icons.select_all_rounded,
                                size: 16,
                                color: allSelected
                                    ? const Color(0xFFFF9F43)
                                    : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                allSelected ? 'deselect_all'.tr : 'select_all'.tr,
                                style: TextStyle(
                                  color: allSelected
                                      ? const Color(0xFFFF9F43)
                                      : Colors.grey.shade500,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: Get.locale?.languageCode == 'km' ? 0 : 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Layout Toggle Button
                      GestureDetector(
                        onTap: () => _isDetailView.toggle(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isDetailView.value
                                ? const Color(0xFF4ECDC4).withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isDetailView.value
                                  ? const Color(0xFF4ECDC4)
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            _isDetailView.value
                                ? Icons.grid_view_rounded
                                : Icons.view_list_rounded,
                            size: 18,
                            color: _isDetailView.value
                                ? const Color(0xFF4ECDC4)
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              Flexible(
                child: Obx(() {
                  if (_isDetailView.value) {
                    return _buildDetailListView(hubCtrl);
                  }
                  return _buildCompactGridView(hubCtrl);
                }),
              ),
              const SizedBox(height: 24),

              // ── Section: Input Type ──
              _buildSectionLabel('how_to_play'.tr, Icons.gamepad_rounded),
              const SizedBox(height: 16),
              Obx(() {
                final selectedGamesList = hubCtrl.miniGames
                    .where((g) => _selectedGames.contains(g.id))
                    .toList();

                final availableInputTypes = <String>{};
                for (final game in selectedGamesList) {
                  availableInputTypes.addAll(
                    game.compatibleInputTypes(game.displayType),
                  );
                }

                final inputOptions = availableInputTypes.toList();

                if (_selectedInputType.value != null &&
                    !inputOptions.contains(_selectedInputType.value)) {
                  _selectedInputType.value = null;
                }

                if (inputOptions.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'select_a_game_first'.tr,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final allOptions = <String?>[
                  null, // "Auto" option
                  ...inputOptions,
                ];

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: allOptions.map((option) {
                    final isActive = _selectedInputType.value == option;
                    final icon = _inputTypeIcon(option);

                    return GestureDetector(
                      onTap: () => _selectedInputType.value = option,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        transform: Matrix4.identity()
                          ..scaleByDouble(isActive ? 1.15 : 1.0, isActive ? 1.15 : 1.0, 1.0, 1.0),
                        transformAlignment: Alignment.center,
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFFF9F43)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive ? Colors.white : Colors.transparent,
                            width: isActive ? 4 : 0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isActive
                                  ? const Color(
                                      0xFFFF9F43,
                                    ).withValues(alpha: 0.4)
                                  : Colors.transparent,
                              blurRadius: isActive ? 10 : 0.0,
                              offset: isActive
                                  ? const Offset(0, 4)
                                  : Offset.zero,
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          size: 32,
                          color: isActive ? Colors.white : Colors.grey.shade500,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 32),

              // ── Start button ──
              Obx(
                () => GestureDetector(
                  onTap: _selectedGames.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          _startCustomRun();
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: _selectedGames.isEmpty
                          ? Colors.grey.shade300
                          : const Color(0xFF4ECDC4),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _selectedGames.isEmpty
                              ? Colors.transparent
                              : const Color(0xFF4ECDC4).withValues(alpha: 0.4),
                          blurRadius: _selectedGames.isEmpty ? 0.0 : 12,
                          offset: _selectedGames.isEmpty
                              ? Offset.zero
                              : const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: _selectedGames.isEmpty
                              ? Colors.grey.shade500
                              : Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'start_playing'.tr,
                          style: TextStyle(
                            color: _selectedGames.isEmpty
                                ? Colors.grey.shade500
                                : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: Get.locale?.languageCode == 'km' ? 0 : 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String text, IconData icon, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: Get.locale?.languageCode == 'km' ? 0 : 1.5,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing],
      ],
    );
  }

  Widget _buildFallbackIcon() {
    return Icon(
      Icons.sports_esports_rounded,
      color: Colors.grey.shade400,
      size: 40,
    );
  }


  Widget _buildCompactGridView(MiniGameHubController hubCtrl) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            ...hubCtrl.miniGames.map((game) {
              return Obx(() {
                final isSelected = _selectedGames.contains(game.id);
                final title = Get.locale?.languageCode == 'km'
                    ? (game.titleKh ?? game.title)
                    : game.title;
                return GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      _selectedGames.remove(game.id);
                    } else {
                      _selectedGames.add(game.id);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    transform: Matrix4.identity()
                      ..scaleByDouble(isSelected ? 1.15 : 1.0, isSelected ? 1.15 : 1.0, 1.0, 1.0),
                    transformAlignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF4ECDC4)
                                  : Colors.transparent,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(0xFF4ECDC4).withValues(alpha: 0.4)
                                    : Colors.transparent,
                                blurRadius: isSelected ? 12 : 0.0,
                                offset: isSelected
                                    ? const Offset(0, 6)
                                    : Offset.zero,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: game.coverImageUrl != null &&
                                    game.coverImageUrl!.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Image.network(
                                      Env.backendUrl + game.coverImageUrl!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          _buildFallbackIcon(),
                                    ),
                                  )
                                : _buildFallbackIcon(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 88,
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF4ECDC4)
                                  : Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailListView(MiniGameHubController hubCtrl) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: hubCtrl.miniGames.map((game) {
          return Obx(() {
            final isSelected = _selectedGames.contains(game.id);
            final title = Get.locale?.languageCode == 'km'
                ? (game.titleKh ?? game.title)
                : game.title;
            final description = Get.locale?.languageCode == 'km'
                ? (game.descriptionKh ?? game.description ?? '')
                : game.description ?? '';

            return GestureDetector(
              onTap: () {
                if (isSelected) {
                  _selectedGames.remove(game.id);
                } else {
                  _selectedGames.add(game.id);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4ECDC4).withValues(alpha: 0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4ECDC4)
                        : Colors.grey.shade200,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF4ECDC4).withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover image or fallback
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: game.coverImageUrl != null &&
                              game.coverImageUrl!.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(6),
                              child: Image.network(
                                Env.backendUrl + game.coverImageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    _buildFallbackIcon(),
                              ),
                            )
                          : _buildFallbackIcon(),
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF4ECDC4)
                                  : const Color(0xFF4A4A4A),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],

                        ],
                      ),
                    ),
                    // Selection indicator checkbox or check circle
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFF4ECDC4)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF4ECDC4)
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          });
        }).toList(),
      ),
    );
  }

  IconData _inputTypeIcon(String? type) {
    switch (type) {
      case 'drawing_board':
        return Icons.draw_rounded;
      case 'multiple_choice':
        return Icons.grid_view_rounded;
      case 'drag_and_drop':
        return Icons.touch_app_rounded;
      case 'typing':
        return Icons.keyboard_rounded;
      case null:
      default:
        return Icons.card_giftcard_rounded;
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

class _FloatingStar extends StatefulWidget {
  final double initialTop;
  final double initialLeft;
  final double initialRight;
  final double size;

  const _FloatingStar({
    required this.initialTop,
    required this.initialLeft,
    required this.initialRight,
    required this.size,
  });

  @override
  State<_FloatingStar> createState() => _FloatingStarState();
}

class _FloatingStarState extends State<_FloatingStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late double _top;
  late double _left;
  late double _right;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _top = widget.initialTop;
    _left = widget.initialLeft;
    _right = widget.initialRight;

    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 4000 + _rand.nextInt(3000)),
    );

    _setupAnimation();

    // Randomize initial delay before starting
    Future.delayed(Duration(milliseconds: _rand.nextInt(1500)), () {
      if (mounted) _ctrl.forward();
    });
  }

  void _setupAnimation() {
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(_ctrl);

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;
        setState(() {
          _top = 80 + _rand.nextDouble() * 500;
          if (widget.initialLeft != 0) {
            _left = 10 + _rand.nextDouble() * 100;
          } else {
            _right = 10 + _rand.nextDouble() * 100;
          }
        });

        Future.delayed(Duration(milliseconds: 500 + _rand.nextInt(1500)), () {
          if (mounted) {
            _ctrl.duration = Duration(milliseconds: 4000 + _rand.nextInt(3000));
            _ctrl.forward(from: 0);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      // Fallback in case ctrl is not initialized yet
      animation: _ctrl,
      builder: (context, child) {
        // Gentle floating
        final floatOffset = sin(_ctrl.value * pi * 2) * 15;
        // Gentle rotation
        final rotation = sin(_ctrl.value * pi * 2) * 0.1;

        return Positioned(
          top: _top + floatOffset,
          left: _left != 0 ? _left : null,
          right: _right != 0 ? _right : null,
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.rotate(
              angle: rotation,
              child: Image.asset(
                'assets/images/decorations/cute_star_decor.png',
                width: widget.size,
                height: widget.size,
              ),
            ),
          ),
        );
      },
    );
  }
}
