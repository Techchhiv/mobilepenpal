import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';

class SubscribeModal extends StatelessWidget {
  const SubscribeModal({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    final isSchoolStudent = homeController.hasSchool;

    return GestureDetector(
      onTap: () => Get.back(),
      behavior: HitTestBehavior.translucent,
      child: GestureDetector(
        onTap: () {},
        child: Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          elevation: 8,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: isSchoolStudent
                ? _buildSchoolStudentContent()
                : _buildPublicUserContent(),
          ),
        ),
      ),
    );
  }

  /// Content shown to school-affiliated students.
  /// They need to contact their school admin to activate the subscription.
  Widget _buildSchoolStudentContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Close button row
          Align(
            alignment: Alignment.topRight,
            child: _buildCloseButton(),
          ),

          // Crown icon
          _buildCrownIcon(),
          const SizedBox(height: 20),

          Text(
            'school_subscription_title'.tr,
            style: const TextStyle(
              fontFamily: 'Kantumruy Pro',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'school_subscription_message'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Kantumruy Pro',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
              height: 1.6,
            ),
          ),

          const SizedBox(height: 24),

          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFDE68A),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.school_rounded,
                  color: Color(0xFFD97706),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'contact_school_admin'.tr,
                    style: const TextStyle(
                      fontFamily: 'Kantumruy Pro',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Content shown to public / general users (no school).
  /// They can subscribe directly.
  Widget _buildPublicUserContent() {
    final homeController = Get.find<HomeController>();

    return Obx(() {
      final price = homeController.subscriptionPrice.value;
      final discount = homeController.subscriptionDiscount.value;
      final billingCycle = homeController.subscriptionBillingCycle.value;
      final phone = homeController.contactPhone.value;
      final email = homeController.contactEmail.value;

      final discountedPrice = price * (1 - discount / 100);
      final hasDiscount = discount > 0;

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: _buildCloseButton(),
              ),

              // ===== Header Section =====
              _buildCrownIcon(),
              const SizedBox(height: 16),

              // Main Title Only (Subtitle removed as requested)
              Text(
                'unlock_unlimited_title'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Kantumruy Pro',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 20),

              // ===== Feature Benefits =====
              _buildFeatureItem(
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFD32F2F),
                bgColor: const Color(0xFFE53935),
                title: 'benefit_worlds_title'.tr,
              ),
              const SizedBox(height: 10),
              _buildFeatureItem(
                icon: Icons.draw_rounded,
                iconColor: const Color(0xFF7C3AED),
                bgColor: const Color(0xFF8B5CF6),
                title: 'benefit_ai_title'.tr,
              ),
              const SizedBox(height: 10),
              _buildFeatureItem(
                icon: Icons.sports_esports_rounded,
                iconColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFF59E0B),
                title: 'benefit_minigames_title'.tr,
              ),

              const SizedBox(height: 20),

              // ===== Pricing Card =====
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFEFF6FF),
                      Color(0xFFDBEAFE),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFBFDBFE),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (hasDiscount) ...[
                          // Discount badge + strikethrough price
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFEF4444),
                                      Color(0xFFDC2626),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "$discount% OFF",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "\$${price.toStringAsFixed(1)}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                        ],

                        // Main price
                        Text(
                          "\$${discountedPrice.toStringAsFixed(1)}",
                          style: const TextStyle(
                            fontFamily: 'Kantumruy Pro',
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            " / ${billingCycle.tr}",
                            style: const TextStyle(
                              fontFamily: 'Kantumruy Pro',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ===== Contact Section =====
              Text(
                'subscribe_contact_us'.tr,
                style: const TextStyle(
                  fontFamily: 'Kantumruy Pro',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),

              // Contact info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _ContactRow(
                      icon: Icons.phone_rounded,
                      text: phone,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                        height: 1,
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    _ContactRow(
                      icon: Icons.email_rounded,
                      text: email,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close_rounded,
          color: Colors.black54,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildCrownIcon() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFBBF24),
            Color(0xFFF59E0B),
            Color(0xFFD97706),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.workspace_premium_rounded,
        size: 34,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bgColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Kantumruy Pro',
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          // Checkmark
          Icon(
            Icons.check_circle_rounded,
            color: iconColor,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Kantumruy Pro',
              fontSize: 13,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
