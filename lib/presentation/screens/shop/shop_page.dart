import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';

class ShopPage extends StatelessWidget {
  final ShopController controller = Get.find<ShopController>();

  ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPointsHeader(),
        Expanded(
          child: _buildAvatarGrid(),
        ),
      ],
    );
  }

  Widget _buildPointsHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B7A78), Color(0xFF3CB9A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B7A78).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'your_points'.tr.isEmpty ? 'Your Points' : 'your_points'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                      '${controller.totalPoints.value}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    )),
              ],
            ),
          ),
          Obx(() {
            final avatar = controller.currentAvatar;
            return _buildAvatarCircle(avatar, size: 56, showBorder: true);
          }),
        ],
      ),
    );
  }

  Widget _buildAvatarGrid() {
    return Obx(() {
      // Force reactive rebuild when unlocked list or selected changes
      controller.unlockedAvatarIds.length;
      controller.selectedAvatarId.value;

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.78,
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
    return GestureDetector(
      onTap: () => _onAvatarTap(context, avatar, unlocked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? avatar.color : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.white.withValues(alpha: 0.3) : Colors.grey.shade200,
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? avatar.color.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: selected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                _buildAvatarCircle(avatar,
                    size: 64, showBorder: selected),

                // Lock overlay
                if (!unlocked)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),

                // Selected checkmark
                if (selected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.check,
                        color: avatar.color,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              avatar.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : (unlocked ? AppColors.textGray80 : AppColors.textGray40),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            if (!unlocked)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.stars_rounded,
                    size: 14,
                    color: Colors.amber.shade600,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${avatar.price}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              )
            else if (selected)
              Text(
                'In Use',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              )
            else
              const Text(
                'Owned',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGray40,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCircle(ShopAvatar avatar,
      {double size = 64, bool showBorder = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            avatar.color.withValues(alpha: 0.8),
            avatar.color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: showBorder
            ? Border.all(color: Colors.white, width: 3)
            : null,
        boxShadow: [
          BoxShadow(
            color: avatar.color.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: avatar.assetPath != null
          ? ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  avatar.assetPath!,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) {
                    debugPrint('ShopPage: Failed to load asset: ${avatar.assetPath} - Error: $err');
                    return Icon(
                      avatar.icon ?? Icons.person,
                      color: Colors.white,
                      size: size * 0.45,
                    );
                  },
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

  void _onAvatarTap(
    BuildContext context,
    ShopAvatar avatar,
    bool unlocked,
  ) {
    if (unlocked) {
      _showSelectDialog(context, avatar);
    } else {
      _showPurchaseDialog(context, avatar);
    }
  }

  void _showSelectDialog(BuildContext context, ShopAvatar avatar) {
    final isAlreadySelected = controller.isSelected(avatar.id);

    Get.dialog(
      Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Material(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                _buildAvatarCircle(avatar, size: 80),
                const SizedBox(height: 16),
                Text(
                  avatar.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAlreadySelected
                      ? 'This avatar is currently in use!'
                      : 'Use this avatar?',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray60,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (isAlreadySelected)
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(140, 44),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          controller.selectAvatar(avatar.id);
                          Get.back();
                          Get.snackbar(
                            'Avatar Changed!',
                            'Now using ${avatar.name}',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.9),
                            colorText: Colors.white,
                            duration: const Duration(seconds: 2),
                            margin: const EdgeInsets.all(16),
                            borderRadius: 12,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: avatar.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(140, 44),
                        ),
                        child: const Text(
                          'Select',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
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

    Get.dialog(
      Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Material(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                _buildAvatarCircle(avatar, size: 80),
                const SizedBox(height: 16),
                Text(
                  avatar.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      size: 20,
                      color: Colors.amber.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${avatar.price} points',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!hasEnough) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.red.shade400,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Not enough points!\nYou need ${avatar.price - controller.totalPoints.value} more.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(140, 44),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ] else ...[
                  Obx(() => Text(
                        'Your balance: ${controller.totalPoints.value} points',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textGray60,
                        ),
                      )),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          final success = controller.purchaseAvatar(avatar.id);
                          Get.back();
                          if (success) {
                            Get.snackbar(
                              '🎉 Avatar Unlocked!',
                              '${avatar.name} is now yours!',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor:
                                  avatar.color.withValues(alpha: 0.9),
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                              margin: const EdgeInsets.all(16),
                              borderRadius: 12,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: avatar.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(140, 44),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shopping_cart_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Buy for ${avatar.price}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
    barrierDismissible: true,
  );
}
}
