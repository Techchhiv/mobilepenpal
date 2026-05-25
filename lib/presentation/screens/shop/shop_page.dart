import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';

class ShopPage extends StatelessWidget {
  final ShopController controller = Get.find<ShopController>();

  ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F4FF), // soft blue-white (QuestPage style)
              Color(0xFFFFF8F0), // warm peach-white (QuestPage style)
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildBubble(
              top: -40,
              right: -30,
              size: 130,
              color: const Color(0x22845EF7),
            ),
            _buildBubble(
              top: 240,
              left: -20,
              size: 90,
              color: const Color(0x224ECDC4),
            ),
            _buildBubble(
              bottom: 60,
              right: -20,
              size: 110,
              color: const Color(0x22FF6B6B),
            ),

            SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Env.globalMaxWidth,
                  ),
                  child: Column(
                    children: [
                      _buildPointsHeader(),
                      Expanded(child: _buildAvatarGrid(context)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAvatarDisplayName(ShopAvatar avatar) {
    final key = 'avatar_${avatar.id}';
    final translated = key.tr;
    return translated == key ? avatar.name : translated;
  }

  Widget _buildBubble({
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
              BoxShadow(color: color, blurRadius: 26, spreadRadius: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFB74D), // warm orange
            Color(0xFFF57C00), // golden orange
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF57C00).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            left: 30,
            bottom: -35,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),

          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Colors.amber,
                  size: 42,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'your_points'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Obx(
                      () => Text(
                        '${controller.totalPoints.value}',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          shadows: [
                            Shadow(
                              color: Colors.black12,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Obx(() {
                final avatar = controller.currentAvatar;
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _buildAvatarCircle(
                    avatar,
                    size: 56,
                    showBorder: false,
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarGrid(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Obx(() {
      controller.unlockedAvatarIds.length;
      controller.selectedAvatarId.value;

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: isTablet ? 190 : 140,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.76,
        ),
        itemCount: controller.allAvatars.length,
        itemBuilder: (context, index) {
          final avatar = controller.allAvatars[index];
          final unlocked = controller.isUnlocked(avatar.id);
          final selected = controller.isSelected(avatar.id);

          return _buildAvatarCard(
            context,
            avatar: avatar,
            unlocked: unlocked,
            selected: selected,
          );
        },
      );
    });
  }

  Widget _buildAvatarCard(
    BuildContext context, {
    required ShopAvatar avatar,
    required bool unlocked,
    required bool selected,
  }) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final displayName = _getAvatarDisplayName(avatar);

    return BouncyGestureDetector(
      onTap: () => _onAvatarTap(context, avatar, unlocked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: selected
              ? avatar.color
              : (unlocked
                    ? Colors.white
                    : avatar.color.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: selected
                ? Colors.white
                : (unlocked
                      ? avatar.color.withValues(alpha: 0.3)
                      : avatar.color.withValues(alpha: 0.15)),
            width: selected ? 3.5 : 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? avatar.color.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: selected ? 14 : 8,
              offset: selected ? const Offset(0, 6) : const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                _buildAvatarCircle(
                  avatar,
                  size: isTablet ? 86 : 66,
                  showBorder: selected,
                  isLocked: !unlocked,
                ),

                if (!unlocked)
                  Container(
                    width: isTablet ? 86 : 66,
                    height: isTablet ? 86 : 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: isTablet ? 30 : 24,
                    ),
                  ),

                if (selected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: isTablet ? 28 : 22,
                      height: isTablet ? 28 : 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: isTablet ? 18 : 14,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isTablet ? 14 : 10),
            Text(
              displayName,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w900,
                color: selected
                    ? Colors.white
                    : (unlocked
                          ? const Color(0xFF3A3A5C)
                          : Colors.grey.shade500),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            if (!unlocked)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      size: 13,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${avatar.price}',
                      style: TextStyle(
                        fontSize: isTablet ? 13 : 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              )
            else if (selected)
              Text(
                'in_use'.tr,
                style: TextStyle(
                  fontSize: isTablet ? 13 : 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'owned'.tr,
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCircle(
    ShopAvatar avatar, {
    double size = 64,
    bool showBorder = false,
    bool isLocked = false,
  }) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [avatar.color.withValues(alpha: 0.75), avatar.color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: showBorder ? Border.all(color: Colors.white, width: 3.5) : null,
      ),
      child: avatar.assetPath != null
          ? ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Opacity(
                  opacity: isLocked ? 0.5 : 1.0,
                  child: Image.asset(
                    avatar.assetPath!,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) {
                      debugPrint(
                        'ShopPage: Failed to load asset: ${avatar.assetPath} - Error: $err',
                      );
                      return Icon(
                        avatar.icon ?? Icons.person,
                        color: Colors.white,
                        size: size * 0.45,
                      );
                    },
                  ),
                ),
              ),
            )
          : Icon(
              avatar.icon ?? Icons.person,
              color: Colors.white,
              size: size * 0.45,
            ),
    );
  }

  void _onAvatarTap(BuildContext context, ShopAvatar avatar, bool unlocked) {
    if (unlocked) {
      _showSelectDialog(context, avatar);
    } else {
      _showPurchaseDialog(context, avatar);
    }
  }

  void _showSelectDialog(BuildContext context, ShopAvatar avatar) {
    final isAlreadySelected = controller.isSelected(avatar.id);
    final displayName = _getAvatarDisplayName(avatar);

    Get.dialog(
      Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          width: MediaQuery.of(context).size.width * 0.85,
          child: ScaleTransitionWidget(
            child: Material(
              borderRadius: BorderRadius.circular(28),
              color: Colors.white,
              elevation: 10,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: avatar.color.withValues(alpha: 0.35),
                    width: 4.5,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 120,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(23),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                avatar.color.withValues(alpha: 0.15),
                                avatar.color.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -25,
                      left: -15,
                      child: const Text(
                        '🎈',
                        style: TextStyle(fontSize: 36, decoration: TextDecoration.none),
                      ),
                    ),
                    Positioned(
                      top: -15,
                      right: -15,
                      child: const Text(
                        '✨',
                        style: TextStyle(fontSize: 28, decoration: TextDecoration.none),
                      ),
                    ),
                    Positioned(
                      bottom: -15,
                      right: 15,
                      child: const Text(
                        '⭐',
                        style: TextStyle(fontSize: 24, decoration: TextDecoration.none),
                      ),
                    ),
                    Positioned(
                      bottom: -10,
                      left: 15,
                      child: const Text(
                        '🎨',
                        style: TextStyle(fontSize: 24, decoration: TextDecoration.none),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 140,
                              height: 140,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const SunburstWidget(size: 140),
                                  _buildAvatarCircle(
                                    avatar,
                                    size: 90,
                                    showBorder: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF3A3A5C),
                              ),
                            ),
                            if (isAlreadySelected) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFA5D6A7),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF2E7D32),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'in_use'.tr,
                                      style: const TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'avatar_equipped_compliment'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ] else ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8EAF6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFC5CAE9),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.bookmark_added_rounded,
                                      color: Color(0xFF3F51B5),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'owned'.tr,
                                      style: const TextStyle(
                                        color: Color(0xFF3F51B5),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'use_this_avatar'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 24),
                            if (isAlreadySelected)
                              Playful3DButton(
                                label: 'ok'.tr.toUpperCase(),
                                color: AppColors.primary,
                                onTap: () => Navigator.of(context).pop(),
                              )
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  BouncyGestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Text(
                                      'cancel'.tr,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                  Playful3DButton(
                                    label: 'select_avatar'.tr,
                                    color: avatar.color,
                                    onTap: () {
                                      controller.selectAvatar(avatar.id);
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _showPurchaseDialog(BuildContext context, ShopAvatar avatar) {
    final hasEnough = controller.totalPoints.value >= avatar.price;
    final displayName = _getAvatarDisplayName(avatar);

    Get.dialog(
      Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          width: MediaQuery.of(context).size.width * 0.85,
          child: ScaleTransitionWidget(
            child: Material(
              borderRadius: BorderRadius.circular(28),
              color: Colors.white,
              elevation: 10,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: avatar.color.withValues(alpha: 0.35),
                    width: 4.5,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 120,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(23),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                avatar.color.withValues(alpha: 0.15),
                                avatar.color.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -25,
                      left: -15,
                      child: const Text(
                        '🎈',
                        style: TextStyle(fontSize: 36, decoration: TextDecoration.none),
                      ),
                    ),
                    Positioned(
                      top: -15,
                      right: -15,
                      child: const Text(
                        '✨',
                        style: TextStyle(fontSize: 28, decoration: TextDecoration.none),
                      ),
                    ),
                    Positioned(
                      bottom: -15,
                      right: 15,
                      child: const Text(
                        '⭐',
                        style: TextStyle(fontSize: 24, decoration: TextDecoration.none),
                      ),
                    ),
                    Positioned(
                      bottom: -10,
                      left: 15,
                      child: const Text(
                        '🎨',
                        style: TextStyle(fontSize: 24, decoration: TextDecoration.none),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 140,
                              height: 140,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const SunburstWidget(size: 140),
                                  _buildAvatarCircle(
                                    avatar,
                                    size: 90,
                                    showBorder: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF3A3A5C),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (!hasEnough) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.orange.shade100,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.lock_rounded,
                                          color: Colors.orange.shade700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'not_enough_points'.tr,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.orange.shade800,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'need_more_points'.trParams({
                                        'amount': '${avatar.price - controller.totalPoints.value}',
                                      }),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'shop_earn_more'.tr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade600,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Playful3DButton(
                                label: 'ok'.tr.toUpperCase(),
                                color: Colors.grey.shade500,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFDF0),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.amber.shade200,
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.shade100.withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'price'.tr,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.stars_rounded,
                                              color: Colors.amber,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'points_count'.trParams({
                                                'count': '${avatar.price}',
                                              }),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Divider(
                                        height: 1,
                                        thickness: 1.5,
                                        color: Colors.amber.shade100,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'your_coins'.tr,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.stars_rounded,
                                              color: Colors.amber,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'points_count'.trParams({
                                                'count': '${controller.totalPoints.value}',
                                              }),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'buy_avatar_confirm'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  BouncyGestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Text(
                                      'cancel'.tr,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                  Playful3DButton(
                                    label: 'buy_for'.trParams({
                                      'price': '${avatar.price}',
                                    }),
                                    icon: Icons.shopping_cart_rounded,
                                    color: Colors.green.shade600,
                                    onTap: () async {
                                      final success = await controller
                                          .purchaseAvatar(avatar.id);
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                        if (success) {
                                          _showCelebrationDialog(context, avatar);
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _showCelebrationDialog(BuildContext context, ShopAvatar avatar) {
    final displayName = _getAvatarDisplayName(avatar);

    Get.dialog(
      Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned.fill(child: ConfettiWidget()),

            Container(
              constraints: const BoxConstraints(maxWidth: 380),
              width: MediaQuery.of(context).size.width * 0.85,
              child: ScaleTransitionWidget(
                child: Material(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const SunburstWidget(
                                size: 180,
                                color: Color(0x66FFB74D),
                              ),
                              _buildAvatarCircle(
                                avatar,
                                size: 100,
                                showBorder: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'congrats_unlock_title'.tr,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF9800),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'congrats_unlock_desc'.trParams({
                            'name': displayName,
                          }),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        Playful3DButton(
                          label: 'great_button'.tr,
                          color: Colors.green.shade600,
                          onTap: () {
                            controller.selectAvatar(avatar.id);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}

class BouncyGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BouncyGestureDetector({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<BouncyGestureDetector> createState() => _BouncyGestureDetectorState();
}

class _BouncyGestureDetectorState extends State<BouncyGestureDetector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

class ScaleTransitionWidget extends StatefulWidget {
  final Widget child;

  const ScaleTransitionWidget({super.key, required this.child});

  @override
  State<ScaleTransitionWidget> createState() => _ScaleTransitionWidgetState();
}

class _ScaleTransitionWidgetState extends State<ScaleTransitionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

class SunburstWidget extends StatefulWidget {
  final double size;
  final Color color;

  const SunburstWidget({
    super.key,
    this.size = 200,
    this.color = const Color(0x55FFB74D),
  });

  @override
  State<SunburstWidget> createState() => _SunburstWidgetState();
}

class _SunburstWidgetState extends State<SunburstWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: RotationTransition(
          turns: _controller,
          alignment: Alignment.center,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: StarburstPainter(color: widget.color, rayCount: 16),
          ),
        ),
      ),
    );
  }
}

class StarburstPainter extends CustomPainter {
  final Color color;
  final int rayCount;

  StarburstPainter({required this.color, this.rayCount = 12});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final angleStep = 2 * math.pi / rayCount;

    for (int i = 0; i < rayCount; i++) {
      if (i % 2 == 0) {
        final path = Path();
        final startAngle = i * angleStep;
        final endAngle = (i + 1) * angleStep;

        path.moveTo(center.dx, center.dy);
        path.lineTo(
          center.dx + radius * math.cos(startAngle),
          center.dy + radius * math.sin(startAngle),
        );
        path.lineTo(
          center.dx + radius * math.cos(endAngle),
          center.dy + radius * math.sin(endAngle),
        );
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StarburstPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.rayCount != rayCount;
}

class Playful3DButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;

  const Playful3DButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final shadowColor = Color.lerp(color, Colors.black, 0.28) ?? Colors.black;

    return BouncyGestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0, 5),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double rotation;
  double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class ConfettiWidget extends StatefulWidget {
  const ConfettiWidget({super.key});

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(_updateParticles);

    final colors = [
      Colors.red,
      Colors.pink,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.amber,
    ];

    for (int i = 0; i < 75; i++) {
      _particles.add(
        ConfettiParticle(
          x: 0.1 + _random.nextDouble() * 0.8,
          y: -0.1 - _random.nextDouble() * 0.4,
          vx: (_random.nextDouble() - 0.5) * 0.05,
          vy: 0.03 + _random.nextDouble() * 0.06,
          color: colors[_random.nextInt(colors.length)],
          size: 7.0 + _random.nextDouble() * 8.0,
          rotation: _random.nextDouble() * 2 * math.pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.15,
        ),
      );
    }

    _controller.forward();
  }

  void _updateParticles() {
    if (!mounted) return;
    setState(() {
      for (final p in _particles) {
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.0015; // slow drift downwards
        p.rotation += p.rotationSpeed;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: ConfettiPainter(particles: _particles),
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.x < -0.1 || p.x > 1.1 || p.y > 1.1) continue;

      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;

      canvas.save();
      final px = p.x * size.width;
      final py = p.y * size.height;
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.65,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}
