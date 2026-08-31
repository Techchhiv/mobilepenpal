import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF232A3B), width: 2.2),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors ??
                      [
                        const Color(0xFF109E8B).withValues(alpha: 0.92),
                        const Color(0xFF0C7365).withValues(alpha: 0.92),
                      ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF232A3B),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.25),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: isLoadingProfile
                          ? Center(child: shimmerCircle(36))
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
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
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
                      padding: const EdgeInsets.only(right: 4.0),
                      child: trailing!,
                    )
                  else if (showCoin)
                    Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF232A3B), width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF232A3B),
                              offset: Offset(0, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              color: Colors.amber.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 5),
                            Obx(() {
                              final coinVal = homeController.student.value?.coin ?? 0;
                              return Text(
                                NumberFormatUtils.intText(coinVal),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFE67E22),
                                ),
                              );
                            }),
                          ],
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
