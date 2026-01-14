import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;

  final ImagePicker _picker = ImagePicker();

  bool _handled = false;
  bool _torchOn = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = MobileScannerController(
      // Helps devices that fail on fast reopen
      autoStart: false,
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [BarcodeFormat.qrCode],
    );

    _startCamera();
  }

  Future<void> _startCamera() async {
    if (_starting || _handled) return;
    _starting = true;

    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    try {
      await _controller.start();
    } catch (_) {
      // ignore - you can show a snackbar if needed
    } finally {
      _starting = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera();
    }
  }

  @override
  void deactivate() {
    // ensure camera is released when leaving the page
    _controller.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish(String raw) async {
    if (_handled) return;
    _handled = true;

    try {
      await _controller.stop();
    } catch (_) {}

    if (!mounted) return;

    // IMPORTANT: avoid Get.back() here (it triggers snackbar close bug)
    Navigator.of(context).pop(raw);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    if (capture.barcodes.isEmpty) return;

    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    _finish(raw);
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {
      // It's OK to keep Get.snackbar here, it won't crash if Get is set up properly.
      Get.snackbar('scan_qr_title'.tr, 'flash_unavailable'.tr);
    }
  }

  Future<void> _scanFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      await _controller.stop();

      final BarcodeCapture? capture = await _controller.analyzeImage(file.path);

      if (capture == null || capture.barcodes.isEmpty) {
        Get.snackbar('scan_qr_title'.tr, 'no_qr_found'.tr);
        await _startCamera();
        return;
      }

      final rawValue = capture.barcodes.first.rawValue;
      if (rawValue == null || rawValue.isEmpty) {
        Get.snackbar('scan_qr_title'.tr, 'invalid_qr'.tr);
        await _startCamera();
        return;
      }

      await _finish(rawValue);
    } catch (_) {
      Get.snackbar('scan_qr_title'.tr, 'scan_failed'.tr);
      await _startCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('scan_qr_title'.tr),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),

          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(width: 2, color: Colors.white70),
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 92,
            child: SafeArea(
              top: false,
              child: Text(
                'align_qr_hint'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: _BottomActionButton(
                      icon: _torchOn ? Icons.flash_off : Icons.flash_on,
                      label: _torchOn ? 'flash_off'.tr : 'flash_on'.tr,
                      onTap: _toggleTorch,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BottomActionButton(
                      icon: Icons.photo_library_outlined,
                      label: 'gallery'.tr,
                      onTap: _scanFromGallery,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
