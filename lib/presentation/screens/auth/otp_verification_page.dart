import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/auth/otp_controller.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';

class OtpVerificationPage extends StatelessWidget {
  OtpVerificationPage({super.key});

  final OtpController otpController = Get.find<OtpController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: InkWell(
          onTap: () => Get.offAllNamed('/login'),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'back'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: <Widget>[
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sms_outlined,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'enter_verification_code'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'we_sent_code_to'.tr,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // Phone number doesn't change, so no need for reactive widget
                  Text(
                    otpController.maskedPhoneNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Pin Code Field - only reacts to hasError changes
              Obx(() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: PinCodeTextField(
                  appContext: context,
                  length: 6,
                  obscureText: false,
                  animationType: AnimationType.fade,
                  keyboardType: TextInputType.number,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12),
                    fieldHeight: 50,
                    fieldWidth: 45,
                    activeFillColor: Colors.grey.shade50,
                    inactiveFillColor: Colors.grey.shade50,
                    selectedFillColor: Colors.grey.shade50,
                    activeColor: otpController.hasError.value
                        ? Colors.red
                        : AppColors.primary,
                    inactiveColor: Colors.grey.shade300,
                    selectedColor: AppColors.primary,
                  ),
                  animationDuration: const Duration(milliseconds: 300),
                  backgroundColor: Colors.white,
                  enableActiveFill: true,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  onCompleted: (v) {
                    // Auto-verify is handled in onChanged
                  },
                  onChanged: (value) {
                    otpController.onOtpChanged(value);
                  },
                  beforeTextPaste: (text) {
                    return true;
                  },
                ),
              )),
              const SizedBox(height: 32),

              // Resend OTP Section - only reacts to countdown and canResend
              Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'didnt_receive_code'.tr,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: otpController.canResend.value
                        ? () => otpController.resendOtp()
                        : null,
                    child: Text(
                      otpController.countdownText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: otpController.canResend.value
                            ? AppColors.primary
                            : Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              )),

              const Spacer(),

              // Verify Button - only reacts to isLoading and otpCode
              Obx(() => otpController.isLoading.value
                  ? Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(12),
                      child: const CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: otpController.otpCode.value.length == 6 && 
                                  !otpController.isLoading.value
                            ? () => otpController.verifyOtp()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: otpController.otpCode.value.length == 6 && 
                                         !otpController.isLoading.value
                              ? AppColors.primary
                              : Colors.grey[400],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'verify'.tr.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
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
}