import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/auth/register_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/country_code_picker.dart';

class RegisterPage extends GetView<RegisterController> {
  const RegisterPage({super.key});

  static const Color _brand = Color(0xFF00897B);
  static const Color _dark = Color(0xFF1A1A2E);
  static const Color _bg = Color(0xFFF5F6FA);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    children: [
                      // Hero section
                      _buildHeroSection(),
                      const SizedBox(height: 24),

                      // Student Information section
                      _buildSectionLabel('student'.tr),
                      const SizedBox(height: 10),
                      _FormCard(
                        children: [
                          Obx(
                            () => _buildTextField(
                              icon: Icons.person_outline_rounded,
                              iconColor: _brand,
                              label: 'first_name'.tr,
                              hintText: 'enter_first_name'.tr,
                              textController:
                                  controller.studentFirstNameController,
                              errorText: controller.isSubmitted.value
                                  ? controller.studentFirstNameError.value
                                  : null,
                              isLoading: controller.isLoading.value,
                              onChanged: controller.validateStudentFirstName,
                              required: true,
                            ),
                          ),
                          const _CardDivider(),
                          Obx(
                            () => _buildTextField(
                              icon: Icons.badge_outlined,
                              iconColor: const Color(0xFF5C6BC0),
                              label: 'last_name'.tr,
                              hintText: 'enter_last_name'.tr,
                              textController:
                                  controller.studentLastNameController,
                              errorText: controller.isSubmitted.value
                                  ? controller.studentLastNameError.value
                                  : null,
                              isLoading: controller.isLoading.value,
                              onChanged: controller.validateStudentLastName,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Parent Information section
                      _buildSectionLabel('parent'.tr),
                      const SizedBox(height: 10),
                      _FormCard(
                        children: [
                          Obx(
                            () => _buildTextField(
                              icon: Icons.supervisor_account_outlined,
                              iconColor: const Color(0xFF1E88E5),
                              label: 'parent_first_name'.tr,
                              hintText: 'enter_parent_first_name'.tr,
                              textController:
                                  controller.parentFirstNameController,
                              errorText: controller.isSubmitted.value
                                  ? controller.parentFirstNameError.value
                                  : null,
                              isLoading: controller.isLoading.value,
                              onChanged: controller.validateParentFirstName,
                              required: true,
                            ),
                          ),
                          const _CardDivider(),
                          Obx(
                            () => _buildTextField(
                              icon: Icons.family_restroom_outlined,
                              iconColor: const Color(0xFF00ACC1),
                              label: 'parent_last_name'.tr,
                              hintText: 'enter_parent_last_name'.tr,
                              textController:
                                  controller.parentLastNameController,
                              errorText: controller.isSubmitted.value
                                  ? controller.parentLastNameError.value
                                  : null,
                              isLoading: controller.isLoading.value,
                              onChanged: controller.validateParentLastName,
                              required: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Account section
                      _buildSectionLabel('account'.tr),
                      const SizedBox(height: 10),

                      // Segmented Tab Selector
                      Obx(
                        () => Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F2F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildSegmentTab(
                                  title: 'register_via_phone'.tr,
                                  icon: Icons.phone_android_rounded,
                                  isSelected: controller.registerMethod.value == 'phone',
                                  onTap: () => controller.setRegisterMethod('phone'),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _buildSegmentTab(
                                  title: 'register_via_email'.tr,
                                  icon: Icons.email_outlined,
                                  isSelected: controller.registerMethod.value == 'email',
                                  onTap: () => controller.setRegisterMethod('email'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _FormCard(
                        children: [
                          Obx(() {
                            final isPhoneTab = controller.registerMethod.value == 'phone';
                            final showSecondary = controller.showSecondaryContact.value;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isPhoneTab) ...[
                                  _buildTextField(
                                    icon: Icons.phone_outlined,
                                    iconColor: const Color(0xFF43A047),
                                    label: 'phone_number'.tr,
                                    hintText: 'enter_your_phone_number'.tr,
                                    textController: controller.phoneController,
                                    prefixWidget: CountryCodePicker(
                                      selectedCountry: controller.selectedCountry,
                                      enabled: !controller.isLoading.value,
                                    ),
                                    errorText: controller.isSubmitted.value
                                        ? controller.phoneError.value
                                        : null,
                                    isLoading: controller.isLoading.value,
                                    onChanged: controller.validatePhone,
                                    keyboardType: TextInputType.phone,
                                    required: true,
                                  ),
                                  if (showSecondary) ...[
                                    const _CardDivider(),
                                    _buildTextField(
                                      icon: Icons.email_outlined,
                                      iconColor: const Color(0xFF8E24AA),
                                      label: '${'email'.tr} (${'optional'.tr})',
                                      hintText: 'enter_your_email'.tr,
                                      textController: controller.emailController,
                                      errorText: controller.isSubmitted.value
                                          ? controller.emailError.value
                                          : null,
                                      isLoading: controller.isLoading.value,
                                      onChanged: controller.validateEmail,
                                      keyboardType: TextInputType.emailAddress,
                                      required: false,
                                    ),
                                  ],
                                ] else ...[
                                  _buildTextField(
                                    icon: Icons.email_outlined,
                                    iconColor: const Color(0xFF8E24AA),
                                    label: 'email'.tr,
                                    hintText: 'enter_your_email'.tr,
                                    textController: controller.emailController,
                                    errorText: controller.isSubmitted.value
                                        ? controller.emailError.value
                                        : null,
                                    isLoading: controller.isLoading.value,
                                    onChanged: controller.validateEmail,
                                    keyboardType: TextInputType.emailAddress,
                                    required: true,
                                  ),
                                  if (showSecondary) ...[
                                    const _CardDivider(),
                                    _buildTextField(
                                      icon: Icons.phone_outlined,
                                      iconColor: const Color(0xFF43A047),
                                      label: '${'phone_number'.tr} (${'optional'.tr})',
                                      hintText: 'enter_your_phone_number'.tr,
                                      textController: controller.phoneController,
                                      prefixWidget: CountryCodePicker(
                                        selectedCountry: controller.selectedCountry,
                                        enabled: !controller.isLoading.value,
                                      ),
                                      errorText: controller.isSubmitted.value
                                          ? controller.phoneError.value
                                          : null,
                                      isLoading: controller.isLoading.value,
                                      onChanged: controller.validatePhone,
                                      keyboardType: TextInputType.phone,
                                      required: false,
                                    ),
                                  ],
                                ],
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: InkWell(
                                    onTap: controller.toggleSecondaryContact,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            showSecondary ? Icons.remove_circle_outline : Icons.add_circle_outline,
                                            size: 16,
                                            color: _brand,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            showSecondary
                                                ? 'remove_secondary_contact'.tr
                                                : (isPhoneTab
                                                    ? 'add_optional_email'.tr
                                                    : 'add_optional_phone'.tr),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _brand,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                          const _CardDivider(),
                          Obx(
                            () => _buildPasswordField(
                              icon: Icons.lock_outline_rounded,
                              iconColor: const Color(0xFFEF6C00),
                              label: 'password'.tr,
                              hintText: 'enter_your_password'.tr,
                              textController: controller.passwordController,
                              errorText: controller.isSubmitted.value
                                  ? controller.passwordError.value
                                  : null,
                              isLoading: controller.isLoading.value,
                              isPasswordVisible:
                                  controller.isPasswordVisible.value,
                              onToggleVisibility:
                                  controller.togglePasswordVisibility,
                              onChanged: controller.validatePassword,
                              required: true,
                            ),
                          ),
                          const _CardDivider(),
                          Obx(
                            () => _buildPasswordField(
                              icon: Icons.check_circle_outline_rounded,
                              iconColor: const Color(0xFFE53935),
                              label: 'confirm_password'.tr,
                              hintText: 'confirm_your_new_password'.tr,
                              textController:
                                  controller.confirmPasswordController,
                              errorText: controller.isSubmitted.value
                                  ? controller.confirmPasswordError.value
                                  : null,
                              isLoading: controller.isLoading.value,
                              isPasswordVisible:
                                  controller.isConfirmPasswordVisible.value,
                              onToggleVisibility:
                                  controller.toggleConfirmPasswordVisibility,
                              onChanged: controller.validateConfirmPassword,
                              required: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      _buildSignUpButton(),
                      const SizedBox(height: 16),
                      _buildLoginLink(),
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

        // Back button
        Positioned(
          top: statusBarHeight,
          bottom: 0,
          left: 8,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _BackButton(),
          ),
        ),
      ],
    );
  }


  // ─── Hero Section ───────────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00897B), Color(0xFF00695C)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _brand.withValues(alpha: 0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              size: 34,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'signup'.tr,
            style: TextStyle(
              fontSize: Get.locale?.languageCode == 'km' ? 22 : 20,
              fontWeight: FontWeight.w800,
              color: _dark,
              letterSpacing: Get.locale?.languageCode == 'km' ? 0.0 : -0.3,
            ),
          ),
        ],
      ),
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

  // ─── Text Field ─────────────────────────────────────────────────────
  Widget _buildTextField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String hintText,
    required TextEditingController textController,
    required Function(String) onChanged,
    String? errorText,
    bool isLoading = false,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefixWidget,
  }) {
    final bool isKhmer = Get.locale?.languageCode == 'km';
    final bool hasError = errorText != null && errorText.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 54),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isKhmer ? 14 : 12,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                    letterSpacing: isKhmer ? 0.0 : -0.1,
                  ),
                ),
                if (required)
                  Text(' *',
                      style: TextStyle(
                          color: const Color(0xFFE53935),
                          fontSize: isKhmer ? 14 : 12,
                          fontWeight: FontWeight.w700)),
              ],
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
              if (prefixWidget != null) ...[
                prefixWidget,
                const SizedBox(width: 8),
              ],
              // Field
              Expanded(
                child: TextFormField(
                  controller: textController,
                  onChanged: onChanged,
                  keyboardType: keyboardType,
                  enabled: !isLoading,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _dark,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isLoading
                          ? Colors.black.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.25),
                      fontWeight: FontWeight.w400,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: isLoading
                        ? const Color(0xFFEEEFF3)
                        : const Color(0xFFF5F6FA),
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
                      borderSide:
                          const BorderSide(color: _brand, width: 1.5),
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
                    errorText: hasError ? errorText : null,
                    errorStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE53935),
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

  // ─── Password Field ─────────────────────────────────────────────────
  Widget _buildPasswordField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String hintText,
    required TextEditingController textController,
    required Function(String) onChanged,
    String? errorText,
    bool isLoading = false,
    required bool isPasswordVisible,
    required VoidCallback onToggleVisibility,
    bool required = false,
  }) {
    final bool isKhmer = Get.locale?.languageCode == 'km';
    final bool hasError = errorText != null && errorText.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 54),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isKhmer ? 14 : 12,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                    letterSpacing: isKhmer ? 0.0 : -0.1,
                  ),
                ),
                if (required)
                  Text(' *',
                      style: TextStyle(
                          color: const Color(0xFFE53935),
                          fontSize: isKhmer ? 14 : 12,
                          fontWeight: FontWeight.w700)),
              ],
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
                  onChanged: onChanged,
                  enabled: !isLoading,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _dark,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isLoading
                          ? Colors.black.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.25),
                      fontWeight: FontWeight.w400,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: isLoading
                        ? const Color(0xFFEEEFF3)
                        : const Color(0xFFF5F6FA),
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
                      borderSide:
                          const BorderSide(color: _brand, width: 1.5),
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
                    errorText: hasError ? errorText : null,
                    errorStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE53935),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.black.withValues(alpha: 0.35),
                        size: 20,
                      ),
                      onPressed: isLoading ? null : onToggleVisibility,
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

  // ─── Sign Up Button ─────────────────────────────────────────────────
  Widget _buildSignUpButton() {
    return Obx(
      () => Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: controller.isLoading.value
                ? [Colors.grey[400]!, Colors.grey[500]!]
                : const [Color(0xFF00897B), Color(0xFF00695C)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: controller.isLoading.value
              ? []
              : [
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
                : controller.registerParent,
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
                      'signup'.tr,
                      style: TextStyle(
                        fontSize:
                            Get.locale?.languageCode == 'km' ? 17 : 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing:
                            Get.locale?.languageCode == 'km' ? 0.0 : 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Login Link ─────────────────────────────────────────────────────
  Widget _buildLoginLink() {
    return Obx(
      () => Center(
        child: InkWell(
          onTap: controller.isLoading.value
              ? null
              : () => Get.offAllNamed(AppRoutes.login),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              '${'already_have_account'.tr} ${'login'.tr}',
              style: TextStyle(
                color: controller.isLoading.value
                    ? Colors.grey[500]
                    : _brand,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bool isKhmer = Get.locale?.languageCode == 'km';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? _brand : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: isKhmer ? 13 : 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _brand : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Reusable Widgets
// ═══════════════════════════════════════════════════════════════════════════

/// Back button matching the setting page style with "Back" text.
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isKhmer = Get.locale?.languageCode == 'km';
    return Obx(() {
      final controller = Get.find<RegisterController>();
      final bool disabled = controller.isLoading.value;
      
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : () => Get.offAllNamed(AppRoutes.login),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: disabled
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'back'.tr,
                  style: TextStyle(
                    fontSize: isKhmer ? 16 : 15,
                    fontWeight: FontWeight.w600,
                    color: disabled
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.white,
                    letterSpacing: isKhmer ? 0.0 : -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
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
