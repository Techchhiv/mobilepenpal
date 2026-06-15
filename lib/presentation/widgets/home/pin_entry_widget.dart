import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/home/pin_controller.dart';
import 'package:mobilepenpal/data/services/home_service.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';

class PinWidget extends StatefulWidget {
  final PinMode mode;
  final HomeService? homeService;
  final String? title;
  final String? subtitle;
  final String? confirmTitle;
  final String? confirmSubtitle;
  final bool autoCloseOnSuccess;
  final Future<void> Function()? onSuccess;
  final bool returnToSettings;

  const PinWidget({
    super.key,
    required this.mode,
    this.homeService,
    this.title,
    this.subtitle,
    this.confirmTitle,
    this.confirmSubtitle,
    this.autoCloseOnSuccess = true,
    this.onSuccess,
    this.returnToSettings = false,
  });

  @override
  State<PinWidget> createState() => _PinWidgetState();
}

class _PinWidgetState extends State<PinWidget> {
  late final PinController controller;
  late final String controllerTag;

  @override
  void initState() {
    super.initState();
    controllerTag = 'pin_${widget.mode.name}';
    controller = Get.put(
      PinController(homeService: widget.homeService),
      tag: controllerTag,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialize(widget.mode, widget.returnToSettings);
    });
  }

  @override
  void dispose() {
    Get.delete<PinController>(tag: controllerTag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E6B63),
      body: LoadingOverlay(
        isLoading: controller.loading,
        child: Obx(
          () => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(controller),
                        const SizedBox(height: 20),
                        _buildDotField(controller),
                        if (controller.error.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              controller.error,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildNumpad(controller),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        InkWell(
          onTap: () => Get.key.currentState?.pop<bool>(false),
          child: Text(
            "back".tr,
            style: TextStyle(color: AppColors.textWhiteOff),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container()),
      ],
    );
  }

  Widget _buildHeader(PinController controller) {
    final headerTitle = controller.getTitle(widget.mode, widget.title, widget.confirmTitle);

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF056E6D),
            border: Border.all(color: const Color(0xFF2D8584), width: 3),
          ),
          child: const Icon(Icons.lock, color: Colors.white70, size: 56),
        ),
        const SizedBox(height: 12),
        Text(
          headerTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDotField(PinController controller) {
    final activeController = controller.getActiveController(widget.mode);
    final len = activeController.text.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final filled = index < len;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? Colors.white : Colors.transparent,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNumpadButton({
    required Widget child,
    required VoidCallback onTap,
    required String id,
    bool showBorder = true,
    required PinController controller,
  }) {
    final pressed = controller.pressedButton == id;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 74,
        height: 74,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: pressed
              ? Colors.white.withValues(alpha: 0.28)
              : Colors.transparent,
          border: showBorder
              ? Border.all(color: Colors.white54, width: 1.5)
              : null,
        ),
        child: child,
      ),
    );
  }

  Widget _buildNumpad(PinController controller) {
    Widget num(int n) => _buildNumpadButton(
      child: Text(
        '$n',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () => controller.onNumberTap(n, widget.mode),
      id: '$n',
      controller: controller,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Env.globalMaxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final row in [
              [1, 2, 3],
              [4, 5, 6],
              [7, 8, 9],
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map((n) => num(n)).toList(),
                ),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNumpadButton(
                  child: const Text(
                    'C',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => controller.onClear(widget.mode),
                  id: 'clear',
                  showBorder: false,
                  controller: controller,
                ),
                num(0),
                _buildNumpadButton(
                  child: const Icon(
                    Icons.backspace_outlined,
                    color: Colors.white,
                  ),
                  onTap: () => controller.onBackspace(widget.mode),
                  id: 'backspace',
                  showBorder: false,
                  controller: controller,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
