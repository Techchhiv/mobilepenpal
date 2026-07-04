import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/app_constants.dart';
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

class _PinWidgetState extends State<PinWidget> with SingleTickerProviderStateMixin {
  late final PinController controller;
  late final String controllerTag;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  Worker? _errorWorker;

  @override
  void initState() {
    super.initState();
    controllerTag = 'pin_${widget.mode.name}';
    controller = Get.put(
      PinController(homeService: widget.homeService),
      tag: controllerTag,
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialize(widget.mode, widget.returnToSettings);
      
      _errorWorker = ever(controller.errorRx, (String errMsg) {
        if (errMsg.isNotEmpty) {
          _shakeController.forward(from: 0.0);
        }
      });
    });

    controller.pinController.addListener(_onTextChange);
    controller.confirmController.addListener(_onTextChange);
  }

  void _onTextChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller.pinController.removeListener(_onTextChange);
    controller.confirmController.removeListener(_onTextChange);
    _errorWorker?.dispose();
    _shakeController.dispose();
    Get.delete<PinController>(tag: controllerTag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E6B63),
      body: Obx(
        () => LoadingOverlay(
          isLoading: controller.loading,
          child: SafeArea(
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
        IconButton(
          onPressed: () => Get.key.currentState?.pop<bool>(false),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            padding: const EdgeInsets.all(12),
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
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF0EA399), Color(0xFF0E6B63)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 3),
          ),
          child: const Icon(Icons.lock_rounded, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 16),
        Text(
          headerTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDotField(PinController controller) {
    final activeController = controller.getActiveController(widget.mode);
    final len = activeController.text.length;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0.0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final filled = index < len;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: filled ? 20 : 16,
            height: filled ? 20 : 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? Colors.white : Colors.transparent,
              border: Border.all(
                color: filled ? Colors.white : Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNumpadButton({
    required Widget child,
    required VoidCallback onTap,
    required String id,
    bool showBorder = true,
    required PinController controller,
  }) {
    return _NumpadButton(
      onTap: onTap,
      showBorder: showBorder,
      child: child,
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
        constraints: const BoxConstraints(maxWidth: AppConstants.globalMaxWidth),
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

class _NumpadButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool showBorder;

  const _NumpadButton({
    required this.child,
    required this.onTap,
    this.showBorder = true,
  });

  @override
  State<_NumpadButton> createState() => _NumpadButtonState();
}

class _NumpadButtonState extends State<_NumpadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: 74,
        height: 74,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isPressed
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.transparent,
          border: widget.showBorder
              ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.8)
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
