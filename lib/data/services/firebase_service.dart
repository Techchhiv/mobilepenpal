import 'dart:async';
import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class FirebaseService extends GetxService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxString verificationId = ''.obs;
  final RxBool isOtpSent = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  int? resendToken;

  /// Formats Cambodian phone numbers to international E.164 format (+855XXXXXXXX)
  static String formatCambodianPhone(String phoneNumber) {
    String clean = phoneNumber.trim().replaceAll(RegExp(r'[^\d+]'), '');

    if (clean.startsWith('+855')) {
      return clean;
    }
    if (clean.startsWith('855')) {
      return '+$clean';
    }
    if (clean.startsWith('0')) {
      return '+855${clean.substring(1)}';
    }
    if (!clean.startsWith('+')) {
      return '+855$clean';
    }
    return clean;
  }

  /// Sends OTP to the given phone number via Firebase
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    Function(PhoneAuthCredential credential)? onAutoVerify,
  }) async {
    final completer = Completer<void>();

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final formattedPhone = formatCambodianPhone(phoneNumber);
      dev.log('Sending OTP to: $formattedPhone', name: 'FirebaseService');

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          isLoading.value = false;
          dev.log('Phone verification auto-completed', name: 'FirebaseService');
          if (!completer.isCompleted) completer.complete();
          if (onAutoVerify != null) {
            onAutoVerify(credential);
          } else {
            await _auth.signInWithCredential(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          isLoading.value = false;
          dev.log('Phone verification failed: ${e.code} - ${e.message}', name: 'FirebaseService');
          final friendlyError = _mapFirebaseError(e);
          errorMessage.value = friendlyError;
          if (!completer.isCompleted) completer.complete();
          onError(friendlyError);
        },
        codeSent: (String vId, int? rToken) {
          isLoading.value = false;
          verificationId.value = vId;
          resendToken = rToken;
          isOtpSent.value = true;
          errorMessage.value = '';
          dev.log('OTP code sent. Verification ID: $vId', name: 'FirebaseService');
          if (!completer.isCompleted) completer.complete();
          onCodeSent(vId);
        },
        codeAutoRetrievalTimeout: (String vId) {
          verificationId.value = vId;
          dev.log('Auto-retrieval timeout for: $vId', name: 'FirebaseService');
        },
      );

      // Wait until Firebase completes callback (or 30s timeout fallback)
      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );
    } catch (e) {
      isLoading.value = false;
      dev.log('Exception in sendOtp: $e', name: 'FirebaseService');
      final errorMsg = (e is FirebaseAuthException)
          ? _mapFirebaseError(e)
          : 'something_went_wrong'.tr;
      errorMessage.value = errorMsg;
      onError(errorMsg);
    }
  }

  /// Verifies the entered SMS code with Firebase
  Future<User?> verifyOtp({
    required String smsCode,
    String? customVerificationId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final vId = (customVerificationId != null && customVerificationId.isNotEmpty)
          ? customVerificationId
          : verificationId.value;

      if (vId.isEmpty) {
        throw FirebaseAuthException(
          code: 'session-expired',
          message: 'Verification session has expired. Please resend the code.',
        );
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: vId,
        smsCode: smsCode.trim(),
      );

      final userCredential = await _auth.signInWithCredential(credential);
      isLoading.value = false;
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      final friendlyError = _mapFirebaseError(e);
      errorMessage.value = friendlyError;
      dev.log('Verify OTP error: ${e.code} - ${e.message}', name: 'FirebaseService');
      throw Exception(friendlyError);
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'something_went_wrong'.tr;
      dev.log('General verifyOtp error: $e', name: 'FirebaseService');
      throw Exception('something_went_wrong'.tr);
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'invalid_phone'.tr;
      case 'too-many-requests':
      case 'quota-exceeded':
        return 'too_many_requests'.tr;
      case 'invalid-verification-code':
        return 'invalid_otp_code'.tr;
      case 'session-expired':
        return 'verification_failed'.tr;
      case 'network-request-failed':
        return 'no_internet'.tr;
      default:
        return 'something_went_wrong'.tr;
    }
  }

  User? get currentUser => _auth.currentUser;

  Future<void> signOut() async {
    await _auth.signOut();
    verificationId.value = '';
    resendToken = null;
    isOtpSent.value = false;
    errorMessage.value = '';
  }

  bool get isUserVerified => _auth.currentUser != null;
}