// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mobilepenpal/data/controllers/auth/otp_controller.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';
// import 'package:mobilepenpal/core/theme/app_colors.dart';

// class OtpVerificationPage extends StatelessWidget {
//   OtpVerificationPage({super.key});

//   final OtpController otpController = Get.find<OtpController>();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: AppColors.primary,
//         elevation: 0,
//         automaticallyImplyLeading: false,
//         title: InkWell(
//           onTap: () => Get.offAllNamed('/login'),
//           borderRadius: BorderRadius.circular(8),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.arrow_back_ios_new_rounded,
//                 color: Colors.white,
//                 size: 20,
//               ),
//               const SizedBox(width: 6),
//               Text(
//                 'back'.tr,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
//           child: Column(
//             children: <Widget>[
//               Column(
//                 children: [
//                   Container(
//                     width: 80,
//                     height: 80,
//                     decoration: BoxDecoration(
//                       color: AppColors.primary.withValues(alpha: 0.1),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.sms_outlined,
//                       size: 40,
//                       color: AppColors.primary,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     'enter_verification_code'.tr,
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.black87,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'we_sent_code_to'.tr,
//                     style: const TextStyle(fontSize: 14, color: Colors.grey),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     otpController.maskedPhoneNumber,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 40),

//               Obx(
//                 () => Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                   child: PinCodeTextField(
//                     appContext: context,
//                     length: 6,
//                     obscureText: false,
//                     animationType: AnimationType.fade,
//                     keyboardType: TextInputType.number,
//                     pinTheme: PinTheme(
//                       shape: PinCodeFieldShape.box,
//                       borderRadius: BorderRadius.circular(12),
//                       fieldHeight: 50,
//                       fieldWidth: 45,
//                       activeFillColor: Colors.grey.shade50,
//                       inactiveFillColor: Colors.grey.shade50,
//                       selectedFillColor: Colors.grey.shade50,
//                       activeColor: otpController.hasError.value
//                           ? Colors.red
//                           : AppColors.primary,
//                       inactiveColor: Colors.grey.shade300,
//                       selectedColor: AppColors.primary,
//                     ),
//                     animationDuration: const Duration(milliseconds: 300),
//                     backgroundColor: Colors.white,
//                     enableActiveFill: true,
//                     textStyle: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                     onCompleted: (v) {
//                       otpController.verifyOtp();
//                     },
//                     onChanged: (value) {
//                       otpController.onOtpChanged(value);
//                     },
//                     beforeTextPaste: (text) {
//                       return true;
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 32),

//               Obx(
//                 () => Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       'didnt_receive_code'.tr,
//                       style: const TextStyle(fontSize: 14, color: Colors.grey),
//                     ),
//                     const SizedBox(width: 4),
//                     GestureDetector(
//                       onTap: otpController.canResend.value
//                           ? () => otpController.resendOtp()
//                           : null,
//                       child: Obx(
//                         () => Text(
//                           otpController.countdownText.value,
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: otpController.canResend.value
//                                 ? AppColors.primary
//                                 : Colors.grey[400],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 40),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }