import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';

class ProfileHeaderCard extends StatelessWidget {
  final String? heroTag;
  final bool showCoin;
  final List<Color>? gradientColors;
  final String? subtitle;
  final Widget? trailing;

  const ProfileHeaderCard({
    super.key,
    this.heroTag = 'hero_profile_header',
    this.showCoin = false,
    this.gradientColors,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();

    return Obx(() {
      final isStudent = homeController.currentMode.value == 'student';
      final isLoadingProfile =
          homeController.isProfileLoading.value &&
          homeController.student.value == null;

      final name = isStudent
          ? homeController.fullName
          : homeController.parentName;

      Widget shimmerBlock({
        required double width,
        required double height,
        double radius = 12,
      }) {
        return Shimmer.fromColors(
          baseColor: Colors.white.withValues(alpha: 0.22),
          highlightColor: Colors.white.withValues(alpha: 0.38),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      }

      Widget shimmerCircle(double size) {
        return Shimmer.fromColors(
          baseColor: Colors.white.withValues(alpha: 0.18),
          highlightColor: Colors.white.withValues(alpha: 0.34),
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        );
      }

      final cardContent = Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors ?? const [AppColors.primary, AppColors.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: isLoadingProfile
                          ? Center(child: shimmerCircle(46))
                          : _buildAvatarContent(homeController),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Text area
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isLoadingProfile) ...[
                          shimmerBlock(width: 170, height: 18, radius: 10),
                          if (subtitle != null) ...[
                            const SizedBox(height: 6),
                            shimmerBlock(width: 100, height: 13, radius: 8),
                          ],
                        ] else ...[
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),

                  if (trailing != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: trailing!,
                    )
                  else if (showCoin)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              color: Colors.amber.shade600,
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            Obx(() {
                              final coinVal = homeController.student.value?.coin ?? 0;
                              return Text(
                                NumberFormatUtils.intText(coinVal),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFE67E22),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: RepaintBoundary(
                        child: Lottie.asset(
                          'assets/animated/cat.json',
                          width: 72,
                          height: 72,
                          repeat: true,
                          animate: true,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(child: _SparklesOverlay()),
              ),
            ),
          ],
        ),
      );

      if (heroTag != null) {
        return Hero(
          tag: heroTag!,
          child: cardContent,
        );
      }
      return cardContent;
    });
  }

  Widget _buildAvatarContent(HomeController homeController) {
    final ShopAvatar? shopAvatar = homeController.currentShopAvatar;

    if (shopAvatar != null && shopAvatar.id != 'default') {
      if (shopAvatar.assetPath != null) {
        return Padding(
          padding: const EdgeInsets.all(2),
          child: Image.asset(shopAvatar.assetPath!, fit: BoxFit.cover),
        );
      }
      return Icon(
        shopAvatar.icon ?? Icons.person,
        size: 34,
        color: Colors.white,
      );
    }

    return const Icon(Icons.person, size: 34, color: Colors.white);
  }
}

class _SparklesOverlay extends StatelessWidget {
  const _SparklesOverlay();

  @override
  Widget build(BuildContext context) {
    final HomeAnimationController anim = Get.find<HomeAnimationController>();

    return AnimatedBuilder(
      animation: anim.bubbleController,
      builder: (_, __) {
        return CustomPaint(
          painter: _BubblesPainter(anim, anim.bubbleController.value),
        );
      },
    );
  }
}

class _BubblesPainter extends CustomPainter {
  final HomeAnimationController anim;
  final double t;

  _BubblesPainter(this.anim, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in anim.bubbles) {
      final u = anim.bubbleU(b);
      final a = anim.bubbleAlphaFromU(u);

      final dx = b.x * size.width;
      final dy = (b.y * size.height) + anim.bubbleYOffsetFromU(u);

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: a)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), b.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
