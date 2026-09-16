import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/auth/otp_controller.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpVerificationPage extends StatelessWidget {
  OtpVerificationPage({super.key});

  final OtpController otpController = Get.find<OtpController>();

  static const Color _brand = Color(0xFF00897B);
  static const Color _dark = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    final bool isKhmer = Get.locale?.languageCode == 'km';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _dark,
              size: 20,
            ),
            onPressed: () => Get.back(),
          ),
          centerTitle: true,
          title: Text(
            'otp_verification'.tr,
            style: TextStyle(
              fontSize: isKhmer ? 17 : 16,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 16),
                // Icon Illustration
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _brand.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      size: 44,
                      color: _brand,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'enter_verification_code'.tr,
                  style: TextStyle(
                    fontSize: isKhmer ? 21 : 20,
                    fontWeight: FontWeight.w800,
                    color: _dark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  'we_sent_code_to'.tr,
                  style: TextStyle(
                    fontSize: isKhmer ? 14 : 13,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                // Masked Phone Number
                Obx(
                  () => Text(
                    otpController.maskedPhoneNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 36),

                // PIN Code Field
                Obx(
                  () => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: PinCodeTextField(
                      appContext: context,
                      length: 6,
                      obscureText: false,
                      animationType: AnimationType.fade,
                      keyboardType: TextInputType.number,
                      autoFocus: true,
                      cursorColor: _brand,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(12),
                        fieldHeight: 52,
                        fieldWidth: 44,
                        activeFillColor: Colors.white,
                        inactiveFillColor: const Color(0xFFF5F6FA),
                        selectedFillColor: Colors.white,
                        activeColor: otpController.hasError.value
                            ? const Color(0xFFE53935)
                            : _brand,
                        inactiveColor: const Color(0xFFE0E0E0),
                        selectedColor: _brand,
                        borderWidth: 1.5,
                      ),
                      animationDuration: const Duration(milliseconds: 200),
                      backgroundColor: Colors.transparent,
                      enableActiveFill: true,
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _dark,
                      ),
                      onCompleted: (v) {
                        otpController.verifyOtp();
                      },
                      onChanged: (value) {
                        otpController.onOtpChanged(value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Resend Countdown
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'didnt_receive_code'.tr,
                        style: TextStyle(
                          fontSize: isKhmer ? 13 : 13,
                          color: Colors.black.withValues(alpha: 0.50),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: otpController.canResend.value &&
                                !otpController.isLoading.value
                            ? () => otpController.resendOtp()
                            : null,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          child: Text(
                            otpController.countdownText.value,
                            style: TextStyle(
                              fontSize: isKhmer ? 14 : 13,
                              fontWeight: FontWeight.w700,
                              color: otpController.canResend.value
                                  ? _brand
                                  : Colors.black.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Submit Button
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: otpController.isLoading.value
                          ? null
                          : () => otpController.verifyOtp(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brand,
                        disabledBackgroundColor: Colors.grey[300],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: otpController.isLoading.value
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
                              'verify'.tr,
                              style: TextStyle(
                                fontSize: isKhmer ? 17 : 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}