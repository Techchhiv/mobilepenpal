import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/models/subscription/bakong_checkout.dart';
import 'package:mobilepenpal/data/services/subscription_service.dart';

class KhqrPaymentDialog extends StatefulWidget {
  final BakongCheckoutModel checkout;

  const KhqrPaymentDialog({
    super.key,
    required this.checkout,
  });

  @override
  State<KhqrPaymentDialog> createState() => _KhqrPaymentDialogState();
}

class _KhqrPaymentDialogState extends State<KhqrPaymentDialog> with WidgetsBindingObserver {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final GlobalKey _qrCardKey = GlobalKey();

  Timer? _countdownTimer;
  Timer? _gentlePollingTimer;

  late int _remainingSeconds;
  int _backgroundCheckCount = 0;
  bool _isBackgroundChecking = false;
  bool _isManualChecking = false;
  bool _isSaving = false;
  bool _isSuccess = false;
  bool _isExpired = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remainingSeconds = widget.checkout.expiresInSeconds;

    _startCountdown();
    _startGentlePolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _gentlePollingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user switches back from banking app (ABA, Bakong, etc.), check status once automatically!
    if (state == AppLifecycleState.resumed && !_isSuccess && !_isExpired) {
      _checkPaymentStatus(isManual: false);
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        _gentlePollingTimer?.cancel();
        setState(() {
          _isExpired = true;
        });
      }
    });
  }

  void _startGentlePolling() {
    // Gentle quota-friendly polling: check at 25s and 50s (max 2 background checks)
    // to strictly preserve the 100 API requests/day limit.
    _gentlePollingTimer = Timer.periodic(const Duration(seconds: 25), (timer) async {
      if (!mounted || _isBackgroundChecking || _isManualChecking || _isSuccess || _isExpired) return;
      if (_backgroundCheckCount >= 2) {
        timer.cancel();
        return;
      }
      _backgroundCheckCount++;
      await _checkPaymentStatus(isManual: false);
    });
  }

  Future<void> _checkPaymentStatus({bool isManual = false, bool simulate = false}) async {
    if (_isSuccess || _isExpired) return;

    if (isManual) {
      if (_isManualChecking) return;
      setState(() {
        _isManualChecking = true;
        _errorMessage = null;
      });
    } else {
      if (_isBackgroundChecking) return;
      _isBackgroundChecking = true;
    }

    try {
      final response = await _subscriptionService.verifyPayment(
        md5: widget.checkout.md5,
        simulate: simulate,
      );

      if (!mounted) return;

      final data = response.data;
      final status = data?['status']?.toString();

      if (status == 'success') {
        _countdownTimer?.cancel();
        _gentlePollingTimer?.cancel();

        setState(() {
          _isSuccess = true;
          _isManualChecking = false;
        });

        // Refresh student profile so all subscriptions & limits unlock immediately
        try {
          if (Get.isRegistered<HomeController>()) {
            final homeCtrl = Get.find<HomeController>();
            await homeCtrl.fetchStudentProfile();
          }
        } catch (_) {}

        // Automatically close after 2.2 seconds of showing success celebration
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (mounted && Navigator.canPop(context)) {
            Get.back(result: true);
          }
        });
      } else {
        if (isManual) {
          setState(() {
            _isManualChecking = false;
            _errorMessage = 'waiting_for_payment'.tr;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (isManual) {
        setState(() {
          _isManualChecking = false;
          _errorMessage = e.toString();
        });
      }
    } finally {
      _isBackgroundChecking = false;
      if (isManual && mounted && _isManualChecking) {
        setState(() {
          _isManualChecking = false;
        });
      }
    }
  }

  Future<void> _saveQrToGallery() async {
    if (_isSaving || _isExpired) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          throw Exception('Storage permission denied. Please allow photos access.');
        }
      }

      final boundary = _qrCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Render boundary not found');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to generate image bytes');
      }

      final pngBytes = byteData.buffer.asUint8List();
      await Gal.putImageBytes(pngBytes, name: 'KHQR_${widget.checkout.billNumber}');

      if (!mounted) return;
      Get.snackbar(
        'Success',
        'qr_saved_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
      );
    } catch (e) {
      debugPrint('Error saving QR code: $e');
      if (!mounted) return;
      final errorMsg = e is GalException ? 'qr_save_failed'.tr : e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Notice',
        errorMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 12,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: _isSuccess ? _buildSuccessContent() : _buildPaymentContent(),
        ),
      ),
    );
  }

  Widget _buildPaymentContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Single Simple Header Banner with KHQR and Close Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'KHQR',
                        style: TextStyle(
                          fontFamily: 'Kantumruy Pro',
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Color(0xFFE11D48),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Bakong KHQR',
                      style: TextStyle(
                        fontFamily: 'Kantumruy Pro',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // RepaintBoundary wrapping the clean QR Card (for high-res photo saving)
                RepaintBoundary(
                  key: _qrCardKey,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Merchant name only
                        Text(
                          widget.checkout.merchantName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Kantumruy Pro',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Amount display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '\$${widget.checkout.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'Kantumruy Pro',
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFE11D48),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.checkout.currency,
                              style: const TextStyle(
                                fontFamily: 'Kantumruy Pro',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // QR Code Container
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isExpired ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: _isExpired
                              ? Container(
                                  width: 190,
                                  height: 190,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.timer_off_rounded, size: 48, color: Color(0xFFEF4444)),
                                      const SizedBox(height: 8),
                                      Text(
                                        'qr_expired_msg'.tr,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: 'Kantumruy Pro',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : QrImageView(
                                  data: widget.checkout.qrString,
                                  version: QrVersions.auto,
                                  size: 190.0,
                                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Color(0xFF0F172A),
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Timer
                if (!_isExpired) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined, size: 15, color: Color(0xFF64748B)),
                      const SizedBox(width: 5),
                      Text(
                        '${'qr_expires_in'.tr}: ${_formatTimer(_remainingSeconds)}',
                        style: const TextStyle(
                          fontFamily: 'Kantumruy Pro',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Kantumruy Pro',
                      fontSize: 12,
                      color: Color(0xFFD97706),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ===== SINGLE ROW: Download QR & Verify Payment Buttons =====
                Row(
                  children: [
                    // Download / Save QR Button
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: _isSaving || _isExpired ? null : _saveQrToGallery,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE11D48)),
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 18, color: Color(0xFFE11D48)),
                          label: Text(
                            'save_qr_btn'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Kantumruy Pro',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            side: const BorderSide(color: Color(0xFFFECDD3), width: 1.4),
                            backgroundColor: const Color(0xFFFFF1F2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Verify Payment Button
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _isManualChecking || _isExpired
                              ? null
                              : () => _checkPaymentStatus(isManual: true),
                          icon: _isManualChecking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline, size: 18),
                          label: Text(
                            _isManualChecking ? 'waiting_for_payment'.tr : 'verify_payment_btn'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Kantumruy Pro',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            backgroundColor: const Color(0xFFE11D48),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Simulation mode if enabled
                if (widget.checkout.simulationMode && !_isExpired) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: _isManualChecking
                          ? null
                          : () => _checkPaymentStatus(isManual: true, simulate: true),
                      icon: const Icon(Icons.science_outlined, size: 16, color: Color(0xFF7C3AED)),
                      label: Text(
                        'simulate_payment_btn'.tr,
                        style: const TextStyle(
                          fontFamily: 'Kantumruy Pro',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDDD6FE), width: 1.2),
                        backgroundColor: const Color(0xFFF5F3FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF86EFAC), width: 2),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF16A34A),
              size: 46,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'payment_successful'.tr,
            style: const TextStyle(
              fontFamily: 'Kantumruy Pro',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'subscription_activated_msg'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Kantumruy Pro',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'Kantumruy Pro',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
