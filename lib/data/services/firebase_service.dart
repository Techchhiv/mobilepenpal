// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';

// class FirebaseService extends GetxService {
//   static final FirebaseAuth _auth = FirebaseAuth.instance;
  
//   var verificationId = ''.obs;
//   var isOtpSent = false.obs;
//   var isLoading = false.obs;
//   var errorMessage = ''.obs;

//   Future<String?> sendOtp(String phoneNumber) async {
//     try {
//       isLoading.value = true;
//       errorMessage.value = '';
      
//       String formattedPhone = _formatCambodianPhone(phoneNumber);

//       await _auth.verifyPhoneNumber(
//         phoneNumber: formattedPhone,
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           await _auth.signInWithCredential(credential);
//           isLoading.value = false;
//         },
//         verificationFailed: (FirebaseAuthException e) {
//           isLoading.value = false;
//           errorMessage.value = "Failed to send OTP: ${e.message}";
//         },
//         codeSent: (String verificationId, int? resendToken) {
//           isLoading.value = false;
//           this.verificationId.value = verificationId;
//           isOtpSent.value = true;
//           errorMessage.value = '';
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {
//           this.verificationId.value = verificationId;
//         },
//         timeout: const Duration(seconds: 60),
//       );
      
//       return errorMessage.value.isEmpty ? null : errorMessage.value;
//     } catch (e) {
//       isLoading.value = false;
//       return "Failed to send OTP: $e";
//     }
//   }

//   String _formatCambodianPhone(String phoneNumber) {
//     String digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
//     if (digits.startsWith('0') && digits.length == 10) {
//       return '+855${digits.substring(1)}';
//     } else if (digits.startsWith('855') && digits.length == 11) {
//       return '+$digits';
//     } else if (digits.length == 9) {
//       return '+855$digits';
//     } else if (digits.startsWith('+855')) {
//       return digits;
//     }
    
//     return phoneNumber;
//   }

//   Future<User?> verifyOtp(String smsCode) async {
//     try {
//       isLoading.value = true;
//       errorMessage.value = '';

//       PhoneAuthCredential credential = PhoneAuthProvider.credential(
//         verificationId: verificationId.value,
//         smsCode: smsCode,
//       );

//       UserCredential userCredential = await _auth.signInWithCredential(credential);
      
//       isLoading.value = false;
//       return userCredential.user;
//     } catch (e) {
//       isLoading.value = false;
//       errorMessage.value = "Invalid OTP: $e";
//       return null;
//     }
//   }

//   User? get currentUser => _auth.currentUser;

//   Future<void> signOut() async {
//     await _auth.signOut();
//     verificationId.value = '';
//     isOtpSent.value = false;
//     errorMessage.value = '';
//   }

//   bool get isUserVerified => _auth.currentUser != null;
// }