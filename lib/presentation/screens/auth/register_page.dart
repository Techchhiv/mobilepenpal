import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/auth/register_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class RegisterPage extends GetView<RegisterController> {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Obx(
          () => InkWell(
            onTap: controller.isLoading.value
                ? null
                : () => Get.offAllNamed(AppRoutes.login),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: controller.isLoading.value
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  'back'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: controller.isLoading.value
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 38,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'signup'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // =========================
              // Student Information
              // =========================
              _sectionHeader('student'.tr, icon: Icons.school_rounded),

              const SizedBox(height: 14),

              _label('first_name'.tr, required: true),
              const SizedBox(height: 8),
              Obx(
                () => TextFormField(
                  controller: controller.studentFirstNameController,
                  enabled: !controller.isLoading.value,
                  decoration: _decoration(
                    hint: 'enter_first_name'.tr,
                    errorText: controller.studentFirstNameError.value,
                    isLoading: controller.isLoading.value,
                  ),
                  onChanged: controller.validateStudentFirstName,
                ),
              ),
              const SizedBox(height: 16),

              _label('last_name'.tr),
              const SizedBox(height: 8),
              Obx(
                () => TextFormField(
                  controller: controller.studentLastNameController,
                  enabled: !controller.isLoading.value,
                  decoration: _decoration(
                    hint: 'enter_last_name'.tr,
                    errorText: controller.studentLastNameError.value,
                    isLoading: controller.isLoading.value,
                  ),
                  onChanged: controller.validateStudentLastName,
                ),
              ),

              const SizedBox(height: 22),

              // =========================
              // Parent Information
              // =========================
              _sectionHeader('parent'.tr, icon: Icons.family_restroom_rounded),
              const SizedBox(height: 14),

              _label('parent_first_name'.tr, required: true),
              const SizedBox(height: 8),
              Obx(
                () => TextFormField(
                  controller: controller.parentFirstNameController,
                  enabled: !controller.isLoading.value,
                  decoration: _decoration(
                    hint: 'enter_parent_first_name'.tr,
                    errorText: controller.parentFirstNameError.value,
                    isLoading: controller.isLoading.value,
                  ),
                  onChanged: controller.validateParentFirstName,
                ),
              ),
              const SizedBox(height: 16),

              _label('parent_last_name'.tr, required: true),
              const SizedBox(height: 8),
              Obx(
                () => TextFormField(
                  controller: controller.parentLastNameController,
                  enabled: !controller.isLoading.value,
                  decoration: _decoration(
                    hint: 'enter_parent_last_name'.tr,
                    errorText: controller.parentLastNameError.value,
                    isLoading: controller.isLoading.value,
                  ),
                  onChanged: controller.validateParentLastName,
                ),
              ),

              const SizedBox(height: 22),

              // =========================
              // Account Information
              // =========================
              _sectionHeader('Account', icon: Icons.lock_rounded),
              const SizedBox(height: 14),

              _label('phone_number'.tr, required: true),
              const SizedBox(height: 8),
              Obx(
                () => TextFormField(
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !controller.isLoading.value,
                  decoration: _decoration(
                    hint: 'enter_your_phone_number'.tr,
                    errorText: controller.phoneError.value,
                    isLoading: controller.isLoading.value,
                  ),
                  onChanged: controller.validatePhone,
                ),
              ),
              const SizedBox(height: 16),

              _label('${'email'.tr} (${'optional'.tr})'),
              const SizedBox(height: 8),
              Obx(
                () => TextFormField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !controller.isLoading.value,
                  decoration: _decoration(
                    // if you later add a dedicated key, replace it.
                    hint: 'enter_your_email_or_phone'.tr,
                    errorText: controller.emailError.value,
                    isLoading: controller.isLoading.value,
                  ),
                  onChanged: controller.validateEmail,
                ),
              ),
              const SizedBox(height: 16),

              _label('password'.tr, required: true),
              const SizedBox(height: 8),
              Obx(
                () => TextFormField(
                  controller: controller.passwordController,
                  obscureText: !controller.isPasswordVisible.value,
                  enabled: !controller.isLoading.value,
                  decoration: _decoration(
                    hint: 'enter_your_password'.tr,
                    errorText: controller.passwordError.value,
                    isLoading: controller.isLoading.value,
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isPasswordVisible.value
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: controller.isLoading.value
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.togglePasswordVisibility,
                    ),
                  ),
                  onChanged: controller.validatePassword,
                ),
              ),
              const SizedBox(height: 16),

              _label('confirm_password'.tr, required: true),
              const SizedBox(height: 8),
              Obx(
                () => TextFormField(
                  controller: controller.confirmPasswordController,
                  obscureText: !controller.isConfirmPasswordVisible.value,
                  enabled: !controller.isLoading.value,
                  decoration: _decoration(
                    hint: 'confirm_your_new_password'.tr,
                    errorText: controller.confirmPasswordError.value,
                    isLoading: controller.isLoading.value,
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isConfirmPasswordVisible.value
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: controller.isLoading.value
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.toggleConfirmPasswordVisibility,
                    ),
                  ),
                  onChanged: controller.validateConfirmPassword,
                ),
              ),

              const SizedBox(height: 28),

              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.registerParent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.isLoading.value
                          ? Colors.grey[400]
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'signup'.tr.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Obx(
                () => Center(
                  child: InkWell(
                    onTap: controller.isLoading.value
                        ? null
                        : () => Get.offAllNamed(AppRoutes.login),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Text(
                        '${'already_have_account'.tr} ${'login'.tr}',
                        style: TextStyle(
                          color: controller.isLoading.value
                              ? Colors.grey[500]
                              : AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: 0.2,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _decoration({
    required String hint,
    required String errorText,
    required bool isLoading,
    Widget? suffixIcon,
  }) {
    final hasError = errorText.isNotEmpty;
    return InputDecoration(
      filled: true,
      fillColor: isLoading ? Colors.grey[300] : Colors.grey[100],
      hintText: hint,
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
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
      errorText: hasError ? errorText : null,
      hintStyle: TextStyle(color: isLoading ? Colors.grey[500] : null),
    );
  }
}
