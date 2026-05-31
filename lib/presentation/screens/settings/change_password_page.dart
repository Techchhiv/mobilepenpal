import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/settings/change_password_controller.dart';

class ChangePasswordPage extends StatelessWidget {
  ChangePasswordPage({super.key});

  final ChangePasswordController controller = Get.put(
    ChangePasswordController(),
  );
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  static const Color _brand = Color(0xFF00897B);
  static const Color _dark = Color(0xFF1A1A2E);
  static const Color _bg = Color(0xFFF5F6FA);

  void _dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _dismissKeyboard(context),
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    children: [
                      _buildSectionLabel('password_information'.tr),
                      const SizedBox(height: 10),
                      _FormCard(
                        children: [
                          Obx(
                            () => _buildPasswordField(
                              icon: Icons.lock_open_rounded,
                              iconColor: _brand,
                              label: 'current_password'.tr,
                              hintText: 'enter_current_password'.tr,
                              textController: _currentPasswordController,
                              errorText: controller.currentPasswordError.value,
                              isPasswordVisible:
                                  controller.isCurrentPasswordVisible.value,
                              onToggleVisibility:
                                  controller.toggleCurrentPasswordVisibility,
                            ),
                          ),
                          const _CardDivider(),
                          Obx(
                            () => _buildPasswordField(
                              icon: Icons.lock_outline_rounded,
                              iconColor: const Color(0xFF5C6BC0),
                              label: 'new_password'.tr,
                              hintText: 'enter_new_password'.tr,
                              textController: _newPasswordController,
                              errorText: controller.newPasswordError.value,
                              isPasswordVisible:
                                  controller.isNewPasswordVisible.value,
                              onToggleVisibility:
                                  controller.toggleNewPasswordVisibility,
                            ),
                          ),
                          const _CardDivider(),
                          Obx(
                            () => _buildPasswordField(
                              icon: Icons.check_circle_outline_rounded,
                              iconColor: const Color(0xFFEF6C00),
                              label: 'confirm_new_password'.tr,
                              hintText: 'confirm_your_new_password'.tr,
                              textController: _confirmPasswordController,
                              errorText: controller.confirmPasswordError.value,
                              isPasswordVisible:
                                  controller.isConfirmPasswordVisible.value,
                              onToggleVisibility:
                                  controller.toggleConfirmPasswordVisibility,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildSaveButton(context),
                      const SizedBox(height: 16),
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

  // ─── Header ─────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double headerHeight = 56 + statusBarHeight;

    return Stack(
      children: [
        // Gradient background
        Container(
          height: headerHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00897B), Color(0xFF00695C)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: 5,
                left: -30,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Title (Centered)
        Positioned(
          top: statusBarHeight,
          bottom: 0,
          left: 56,
          right: 56,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              'change_password'.tr,
              style: TextStyle(
                fontSize: Get.locale?.languageCode == 'km' ? 20 : 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: Get.locale?.languageCode == 'km' ? 0.0 : -0.3,
              ),
            ),
          ),
        ),

        // Back button
        Positioned(
          top: statusBarHeight + 4,
          left: 8,
          child: _BackButton(),
        ),
      ],
    );
  }

  // ─── Section Label ──────────────────────────────────────────────────
  Widget _buildSectionLabel(String title) {
    final bool isKhmer = Get.locale?.languageCode == 'km';
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: isKhmer ? 14 : 12,
            fontWeight: FontWeight.w800,
            color: Colors.black.withValues(alpha: 0.35),
            letterSpacing: isKhmer ? 0.0 : 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String hintText,
    required TextEditingController textController,
    String? errorText,
    required bool isPasswordVisible,
    required VoidCallback onToggleVisibility,
  }) {
    final bool isKhmer = Get.locale?.languageCode == 'km';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 54),
            child: Text(
              label,
              style: TextStyle(
                fontSize: isKhmer ? 14 : 12,
                fontWeight: FontWeight.w700,
                color: _dark,
                letterSpacing: isKhmer ? 0.0 : -0.1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              // Field
              Expanded(
                child: TextFormField(
                  controller: textController,
                  obscureText: !isPasswordVisible,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _dark,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.25),
                      fontWeight: FontWeight.w400,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _brand, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFFE53935), width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFFE53935), width: 1.5),
                    ),
                    errorText: errorText?.isNotEmpty == true ? errorText : null,
                    errorStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE53935),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.black.withValues(alpha: 0.35),
                        size: 20,
                      ),
                      onPressed: onToggleVisibility,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Save Button ────────────────────────────────────────────────────
  Widget _buildSaveButton(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF00897B), Color(0xFF00695C)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _brand.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: controller.isLoading.value
                ? null
                : () {
                    _dismissKeyboard(context);
                    controller.changePassword(
                      currentPassword: _currentPasswordController.text,
                      newPassword: _newPasswordController.text,
                      confirmPassword: _confirmPasswordController.text,
                    );
                  },
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'update_password'.tr,
                      style: TextStyle(
                        fontSize: Get.locale?.languageCode == 'km' ? 17 : 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: Get.locale?.languageCode == 'km' ? 0.0 : 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Reusable Widgets
// ═══════════════════════════════════════════════════════════════════════════

/// Back button matching the setting page style.
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        onPressed: () => Get.back(),
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// A card that groups form fields together, matching SettingsCard style.
class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});
  final List<Widget> children;

  static const Color _brand = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Gradient accent bar
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF00897B),
                    Color(0xFF26A69A),
                    Color(0xFF4DB6AC),
                  ],
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A thin fading gradient divider between tiles.
class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.06),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}