import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final ImagePicker _picker = ImagePicker();

  bool _handled = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    if (capture.barcodes.isEmpty) return;

    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    _handled = true;
    Get.back(result: raw);
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      setState(() => _torchOn = !_torchOn);
    } catch (_) {
      Get.snackbar('scan_qr_title'.tr, 'flash_unavailable'.tr);
    }
  }

  Future<void> _scanFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      await _controller.stop();

      final BarcodeCapture? capture =
          await _controller.analyzeImage(file.path);

      if (capture == null || capture.barcodes.isEmpty) {
        Get.snackbar('scan_qr_title'.tr, 'no_qr_found'.tr);
        await _controller.start();
        return;
      }

      final String? rawValue = capture.barcodes.first.rawValue;
      if (rawValue == null || rawValue.isEmpty) {
        Get.snackbar('scan_qr_title'.tr, 'invalid_qr'.tr);
        await _controller.start();
        return;
      }

      _handled = true;
      Get.back(result: rawValue);
    } catch (_) {
      Get.snackbar('scan_qr_title'.tr, 'scan_failed'.tr);
      await _controller.start();
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
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

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
          backgroundColor: Colors.white.withOpacity(0.15),
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
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
