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
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: isSchoolStudent
                    ? _buildSchoolStudentContent()
                    : _buildPublicUserContent(),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Get.back(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Content shown to school-affiliated students.
  /// They need to contact their school admin to activate the subscription.
  Widget _buildSchoolStudentContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'school_subscription_title'.tr,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 24),

        // School icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.school_rounded,
            size: 40,
            color: Colors.orange,
          ),
        ),

        const SizedBox(height: 24),

        // Message
        Text(
          'school_subscription_message'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 24),

        // Info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.orange.shade700,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'contact_school_admin'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'subscription'.tr,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 24),

          // Logo placeholder
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              size: 40,
              color: Colors.blue,
            ),
          ),

          const SizedBox(height: 20),

          // Pricing
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasDiscount) ...[
                // Original price crossed out
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$discount% OFF",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "\$${price.toStringAsFixed(1)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],

              // Discounted price (or full price if no discount)
              Text(
                "\$${discountedPrice.toStringAsFixed(1)} / ${billingCycle.tr}",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Contact Information section
          Text(
            'contact_information'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _ContactRow(icon: Icons.phone, text: phone),
                const SizedBox(height: 8),
                _ContactRow(icon: Icons.email, text: email),
              ],
            ),
          ),
        ],
      );
    });
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
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
