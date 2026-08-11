import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';

/// A dialog shown when a user attempts to log in but their email
/// is not yet verified. Provides a resend button with a 120-second cooldown.
class UnverifiedEmailDialog extends StatefulWidget {
  const UnverifiedEmailDialog({
    super.key,
    required this.email,
    required this.onResend,
  });

  /// The email address that needs verification.
  final String email;

  /// Callback when user taps "Resend". Should return true if the
  /// resend was successful (to restart the cooldown timer).
  final Future<bool> Function() onResend;

  @override
  State<UnverifiedEmailDialog> createState() => _UnverifiedEmailDialogState();
}

class _UnverifiedEmailDialogState extends State<UnverifiedEmailDialog> {
  static const int _cooldownSeconds = 120;

  int _secondsLeft = 0;
  bool _isSending = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  Future<void> _handleResend() async {
    if (_isSending || _secondsLeft > 0) return;
    setState(() => _isSending = true);
    try {
      final success = await widget.onResend();
      if (success && mounted) {
        _startCooldown();
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool canResend = _secondsLeft == 0 && !_isSending;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: Offset(0, 18),
                  color: Color(0x30000000),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => Get.back(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B7280)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Email icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  'email_verification_required'.tr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),

                // Body message
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: const Color(0xFF6B7280),
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(text: '${'verification_sent_to'.tr} '),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      TextSpan(text: '. ${'check_spam_folder'.tr}'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Resend button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canResend ? AppColors.primary : const Color(0xFFE5E7EB),
                      foregroundColor: canResend ? Colors.white : const Color(0xFF9CA3AF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: canResend ? _handleResend : null,
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _secondsLeft > 0
                                ? '${'resend_in'.tr} ${_secondsLeft}s'
                                : 'resend_verification_email'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                // Back to login text button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF111827),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Get.back(),
                    child: Text(
                      'back_to_login'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w800),
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

/// Shows the [UnverifiedEmailDialog] as a dialog overlay.
Future<void> showUnverifiedEmailDialog({
  required String email,
  required Future<bool> Function() onResend,
}) {
  return Get.dialog(
    UnverifiedEmailDialog(email: email, onResend: onResend),
    barrierDismissible: true,
    barrierColor: const Color(0xB3000000),
  );
}
