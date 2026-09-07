import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/services/subscription_service.dart';
import 'package:mobilepenpal/presentation/widgets/home/khqr_payment_dialog.dart';

class SubscribeModal extends StatefulWidget {
  const SubscribeModal({super.key});

  @override
  State<SubscribeModal> createState() => _SubscribeModalState();
}

class _SubscribeModalState extends State<SubscribeModal> {
  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().fetchSubscriptionSettings();
    }
  }

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
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.16),
                  blurRadius: 32,
                  spreadRadius: 2,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top decorative golden ambient glow
                Positioned(
                  top: -40,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.1,
                        colors: [
                          const Color(0xFFFEF3C7).withValues(alpha: 0.7),
                          const Color(0xFFFFFBEB).withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),

                isSchoolStudent
                    ? _buildSchoolStudentContent()
                    : _buildPublicUserContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Content shown to school-affiliated students.
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

          const SizedBox(height: 20),

          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFFDE68A),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE68A).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'contact_school_admin'.tr,
                    style: const TextStyle(
                      fontFamily: 'Kantumruy Pro',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
                      height: 1.4,
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

  /// Content shown to public / general users.
  Widget _buildPublicUserContent() {
    final homeController = Get.find<HomeController>();

    return Obx(() {
      final selectedPlan = homeController.selectedPlan.value;
      final isYearly = selectedPlan == 'yearly';

      final price = isYearly
          ? homeController.yearlyPrice.value
          : homeController.monthlyPrice.value;
      final discount = isYearly
          ? homeController.yearlyDiscount.value
          : homeController.monthlyDiscount.value;
      final billingCycle = isYearly ? 'year' : 'month';
      final phone = homeController.contactPhone.value;
      final email = homeController.contactEmail.value;

      final discountedPrice = price * (1 - discount / 100);
      final hasDiscount = discount > 0;

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top row: Close button
              Align(
                alignment: Alignment.topRight,
                child: _buildCloseButton(),
              ),

              // ===== Hero Badge Section =====
              _buildCrownIcon(),
              const SizedBox(height: 16),

              // Main Title
              Text(
                'unlock_unlimited_title'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Kantumruy Pro',
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 18),

              // ===== Feature Benefits (Polished 3D Gradient Cards) =====
              _buildFeatureItem(
                icon: Icons.favorite_rounded,
                gradientColors: const [Color(0xFFFF6584), Color(0xFFE11D48)],
                shadowColor: const Color(0xFFE11D48),
                title: 'benefit_worlds_title'.tr,
              ),
              const SizedBox(height: 10),
              _buildFeatureItem(
                icon: Icons.draw_rounded,
                gradientColors: const [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                shadowColor: const Color(0xFF7C3AED),
                title: 'benefit_ai_title'.tr,
              ),
              const SizedBox(height: 10),
              _buildFeatureItem(
                icon: Icons.sports_esports_rounded,
                gradientColors: const [Color(0xFFFBBF24), Color(0xFFEA580C)],
                shadowColor: const Color(0xFFEA580C),
                title: 'benefit_minigames_title'.tr,
              ),

              const SizedBox(height: 18),

              // ===== Plan Selector (Monthly vs Yearly) =====
              _PlanSelector(
                selectedPlan: selectedPlan,
                yearlyDiscount: homeController.yearlyDiscount.value,
                onPlanChanged: (plan) {
                  homeController.selectedPlan.value = plan;
                },
              ),

              const SizedBox(height: 14),

              // ===== Pricing Hero Card (VIP Style) =====
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF0F7FF),
                      Color(0xFFEBF3FE),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFBFDBFE),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (hasDiscount) ...[
                          // Discount badge + strikethrough price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
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
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department_rounded,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      "$discount% OFF",
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "\$${price.toStringAsFixed(1)}",
                                style: const TextStyle(
                                  fontSize: 15,
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
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1D4ED8),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 3),
                          child: Text(
                            " / ${billingCycle.tr}",
                            style: const TextStyle(
                              fontFamily: 'Kantumruy Pro',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isYearly && hasDiscount) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFA7F3D0),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          "ត្រឹមតែ ~\$${(discountedPrice / 12).toStringAsFixed(2)} / ខែ • សន្សំសំចៃបំផុត",
                          style: const TextStyle(
                            fontFamily: 'Kantumruy Pro',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ===== Contact Section (Vertical) =====
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
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
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(
                        height: 1,
                        thickness: 0.8,
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

              const SizedBox(height: 18),

              // ===== Bakong KHQR Checkout Button =====
              _BakongCheckoutButton(
                discountedPrice: discountedPrice,
                billingCycle: billingCycle,
                plan: selectedPlan,
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
          color: const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
        child: const Icon(
          Icons.close_rounded,
          color: Color(0xFF64748B),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildCrownIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow aura
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFEF3C7).withValues(alpha: 0.7),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
        ),

        // Inner 3D gradient medal
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFDE047),
                Color(0xFFF59E0B),
                Color(0xFFD97706),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB45309).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            size: 32,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required List<Color> gradientColors,
    required Color shadowColor,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 3D Gradient Icon Box
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),

          // Benefit Title
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Kantumruy Pro',
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                height: 1.3,
              ),
            ),
          ),

          // Emerald Check Badge
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFECFDF5),
              border: Border.all(
                color: const Color(0xFFA7F3D0),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF059669),
              size: 14,
            ),
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
          size: 15,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Kantumruy Pro',
              fontSize: 12.5,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanSelector extends StatelessWidget {
  final String selectedPlan;
  final int yearlyDiscount;
  final ValueChanged<String> onPlanChanged;

  const _PlanSelector({
    required this.selectedPlan,
    required this.yearlyDiscount,
    required this.onPlanChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isYearly = selectedPlan == 'yearly';

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Monthly Option
          Expanded(
            child: GestureDetector(
              onTap: () => onPlanChanged('monthly'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isYearly ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !isYearly
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 16,
                      color: !isYearly
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'monthly'.tr,
                      style: TextStyle(
                        fontFamily: 'Kantumruy Pro',
                        fontSize: 13.5,
                        fontWeight:
                            !isYearly ? FontWeight.w800 : FontWeight.w600,
                        color: !isYearly
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Yearly Option
          Expanded(
            child: GestureDetector(
              onTap: () => onPlanChanged('yearly'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isYearly ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isYearly
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 16,
                      color: isYearly
                          ? const Color(0xFFD97706)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'yearly'.tr,
                      style: TextStyle(
                        fontFamily: 'Kantumruy Pro',
                        fontSize: 13.5,
                        fontWeight:
                            isYearly ? FontWeight.w800 : FontWeight.w600,
                        color: isYearly
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    if (yearlyDiscount > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "-$yearlyDiscount%",
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BakongCheckoutButton extends StatefulWidget {
  final double discountedPrice;
  final String billingCycle;
  final String plan;

  const _BakongCheckoutButton({
    required this.discountedPrice,
    required this.billingCycle,
    required this.plan,
  });

  @override
  State<_BakongCheckoutButton> createState() => _BakongCheckoutButtonState();
}

class _BakongCheckoutButtonState extends State<_BakongCheckoutButton> {
  bool _isLoading = false;
  final SubscriptionService _subscriptionService = SubscriptionService();

  Future<void> _handleCheckout() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _subscriptionService.checkout(plan: widget.plan);

      if (!mounted) return;

      if (response.data != null) {
        final success = await Get.dialog<bool>(
          KhqrPaymentDialog(checkout: response.data!),
          barrierDismissible: false,
        );

        if (success == true) {
          if (Get.isDialogOpen ?? false) {
            Get.back();
          }
        }
      } else {
        Get.snackbar(
          'Error',
          response.message.isNotEmpty ? response.message : 'Failed to generate KHQR',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFE11938), Color(0xFFBE123C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11938).withValues(alpha: 0.38),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Text(
                        'KHQR',
                        style: TextStyle(
                          fontFamily: 'Kantumruy Pro',
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                          color: Color(0xFFE11938),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'pay_with_khqr'.tr,
                      style: const TextStyle(
                        fontFamily: 'Kantumruy Pro',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
