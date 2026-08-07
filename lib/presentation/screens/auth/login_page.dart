import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/auth/auth_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
// import 'package:mobilepenpal/core/utils/phone_number_utils.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final AuthController authController = Get.find<AuthController>();

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
            onTap: authController.isLoading.value
                ? null
                : () => Get.offAllNamed(AppRoutes.splash),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: authController.isLoading.value
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
                    color: authController.isLoading.value
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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
                      child: Image.asset('assets/images/logos/parent.png'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'login'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              Text(
                'email'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => TextFormField(
                  key: const Key('login_email'),
                  controller: authController.emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !authController.isLoading.value,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: authController.isLoading.value
                        ? Colors.grey[300]
                        : Colors.grey[100],
                    hintText: 'enter_your_email'.tr,
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
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    errorText: authController.emailError.value.isNotEmpty
                        ? authController.emailError.value
                        : null,
                    hintStyle: TextStyle(
                      color: authController.isLoading.value
                          ? Colors.grey[500]
                          : null,
                    ),
                  ),
                  onChanged: (value) => authController.validateEmail(value),
                ),
              ),
              /* Phone input field commented out for future switch back if needed:
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [ ... ]
              )
              */
              const SizedBox(height: 24),

              Text(
                'password'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Obx(
                () => TextFormField(
                  key: Key('login_password'),
                  controller: authController.passwordController,
                  obscureText: !authController.isPasswordVisible.value,
                  enabled: !authController.isLoading.value,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: authController.isLoading.value
                        ? Colors.grey[300]
                        : Colors.grey[100],
                    hintText: 'enter_your_password'.tr,
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
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        authController.isPasswordVisible.value
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: authController.isLoading.value
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                      onPressed: authController.isLoading.value
                          ? null
                          : () => authController.togglePasswordVisibility(),
                    ),
                    errorText: authController.passwordError.value.isNotEmpty
                        ? authController.passwordError.value
                        : null,
                    hintStyle: TextStyle(
                      color: authController.isLoading.value
                          ? Colors.grey[500]
                          : null,
                    ),
                  ),
                  onChanged: (value) => authController.validatePassword(value),
                ),
              ),
              SizedBox(height: 32),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                  key: Key('login_submit'),
                    onPressed: authController.isLoading.value
                        ? null
                        : () => authController.login(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: authController.isLoading.value
                          ? Colors.grey[400]
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: authController.isLoading.value
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'loading'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'login'.tr.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Obx(
                () => Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: authController.isLoading.value
                        ? null
                        : () => Get.toNamed(AppRoutes.register),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Text(
                        'register'.tr,
                        style: TextStyle(
                          color: authController.isLoading.value
                              ? AppColors.text.withValues(alpha: 0.5)
                              : AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Obx(
              //   () => Row(
              //     mainAxisAlignment: MainAxisAlignment.end,
              //     children: [
              //       TextButton(
              //         onPressed: authController.isLoading.value
              //             ? null
              //             : () {
              //                 Get.snackbar(
              //                   'Testing'.tr,
              //                   'Change forgot password'.tr,
              //                   backgroundColor: Colors.blue[50],
              //                   colorText: AppColors.primary,
              //                 );
              //               },
              //         child: Text(
              //           'forgot_password'.tr,
              //           style: TextStyle(
              //             color: authController.isLoading.value
              //                 ? AppColors.text.withValues(alpha: 0.5)
              //                 : AppColors.text,
              //             fontSize: 14,
              //             fontWeight: FontWeight.w600,
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
