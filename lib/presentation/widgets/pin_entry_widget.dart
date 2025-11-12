import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/services/home_service.dart';
import 'package:mobilepenpal/presentation/widgets/loading_status.dart';

enum PinMode { create, verify, update }

class PinWidget extends StatefulWidget {
  final PinMode mode;
  final HomeService? homeService;
  final String? title;
  final String? subtitle;
  final String? confirmTitle;
  final String? confirmSubtitle;
  final bool autoCloseOnSuccess;
  final Future<void> Function()? onSuccess;

  const PinWidget({
    Key? key,
    required this.mode,
    this.homeService,
    this.title,
    this.subtitle,
    this.confirmTitle,
    this.confirmSubtitle,
    this.autoCloseOnSuccess = true,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<PinWidget> createState() => _PinWidgetState();
}

class _PinWidgetState extends State<PinWidget> {
  final _secure = const FlutterSecureStorage();
  late final HomeService _homeService;

  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isConfirmStep = false;
  bool _loading = false;
  String? _error;
  String? _pressedButton;

  int _updateStep = 0;

  @override
  void initState() {
    super.initState();
    _homeService = widget.homeService ?? HomeService();
    _isConfirmStep = widget.mode == PinMode.create ? false : false;
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _animatePressed(String id) {
    setState(() => _pressedButton = id);
    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _pressedButton = null);
    });
  }

  void _onNumberTap(int n) {
    if (_loading) return;

    final controller = _getActiveController();
    if (controller.text.length >= 4) return;

    _animatePressed(n.toString());
    controller.text = controller.text + n.toString();
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    if (controller.text.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        if (widget.mode == PinMode.verify) {
          _verifyPin();
        } else if (widget.mode == PinMode.create) {
          if (!_isConfirmStep) {
            setState(() {
              _isConfirmStep = true;
              _error = null;
            });
          } else {
            _createPin();
          }
        } else if (widget.mode == PinMode.update) {
          if (_updateStep == 0) {
            _verifyForUpdate();
          } else {
            if (!_isConfirmStep) {
              setState(() {
                _isConfirmStep = true;
                _error = null;
              });
            } else {
              _createPin(isUpdate: true);
            }
          }
        }
      });
    }
  }

  void _onBackspace() {
    if (_loading) return;

    final controller = _getActiveController();
    _animatePressed('backspace');

    if (controller.text.isEmpty) {
      if (_isConfirmStep) {
        setState(() {
          _isConfirmStep = false;
          _error = null;
        });
      }
      return;
    }

    controller.text = controller.text.substring(0, controller.text.length - 1);
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
  }

  void _onClear() {
    if (_loading) return;
    final controller = _getActiveController();
    _animatePressed('clear');
    controller.clear();
    setState(() {
      _error = null;
    });
  }

  TextEditingController _getActiveController() {
    if (widget.mode == PinMode.create) {
      return _isConfirmStep ? _confirmController : _pinController;
    } else if (widget.mode == PinMode.verify) {
      return _pinController;
    } else {
      if (_updateStep == 0) return _pinController;
      return _isConfirmStep ? _confirmController : _pinController;
    }
  }

  Future<void> _verifyPin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final entered = _pinController.text;
    final stored = await _secure.read(key: 'parent_pin');

    await Future.delayed(const Duration(milliseconds: 150));

    if (stored != null && stored == entered) {
      try {
        widget.onSuccess?.call();
      } catch (_) {}

      Get.back(result: true);
      return;
    } else {
      if (!mounted) return;
      setState(() {
        _error = 'invalid_pin'.tr;
        _pinController.clear();
        _loading = false;
      });
    }
  }

  Future<void> _verifyForUpdate() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final entered = _pinController.text;
    final stored = await _secure.read(key: 'parent_pin');

    await Future.delayed(const Duration(milliseconds: 150));

    if (stored != null && stored == entered) {
      setState(() {
        _updateStep = 1;
        _isConfirmStep = false;
        _pinController.clear();
        _confirmController.clear();
        _loading = false;
      });
    } else {
      setState(() {
        _error = 'invalid_pin'.tr;
        _pinController.clear();
        _loading = false;
      });
    }
  }

  Future<void> _createPin({bool isUpdate = false}) async {
    final pin = _pinController.text;
    final confirm = _confirmController.text;

    if (pin.length != 4 || confirm.length != 4) {
      setState(() => _error = 'enter_digits'.tr);
      return;
    }
    if (pin != confirm) {
      setState(() {
        _error = 'pins_do_not_match'.tr;
        _confirmController.clear();
      });
      return;
    }

    FocusScope.of(context).unfocus();

    Get.offAll(() => const LoadingStatus(isLoading: true, isSuccess: false));

    try {
      final res = await _homeService.updateParentPin(pin);

      if (res.code == 200) {
        await _secure.write(key: 'parent_pin', value: pin);

        Get.offAll(
          () => LoadingStatus(
            isLoading: false,
            isSuccess: true,
            successText: isUpdate
                ? 'success_pin_updated'.tr
                : 'success_pin_created'.tr,
            buttonText: 'continue'.tr,
            onButtonPressed: () {
              GetStorage().write('skip_parent_pin_setup', false);
              Get.offAllNamed('/home');
            },
          ),
        );
      } else {
        Get.back();
        setState(() {
          _error = res.message;
        });
        Get.snackbar(
          'error'.tr,
          _error!,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back();
      setState(() {
        _error = e.toString();
      });
      Get.snackbar(
        'error'.tr,
        _error!,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        InkWell(
          onTap: () => Get.back(result: false),
          child: Text(
            "ត្រឡប់ក្រោយ",
            style: TextStyle(color: AppColors.textWhiteOff),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container()),
      ],
    );
  }

  Widget _buildHeader() {
    String title;
    String subtitle;

    if (widget.mode == PinMode.verify) {
      title = widget.title ?? 'enter_pin'.tr;
      subtitle = widget.subtitle ?? '';
    } else if (widget.mode == PinMode.create) {
      title = _isConfirmStep
          ? (widget.confirmTitle ?? 'confirm_pin'.tr)
          : (widget.title ?? 'create_pin'.tr);
      subtitle = widget.subtitle ?? '';
    } else {
      if (_updateStep == 0) {
        title = widget.title ?? 'enter_current_pin'.tr;
        subtitle = widget.subtitle ?? '';
      } else {
        title = _isConfirmStep
            ? (widget.confirmTitle ?? 'confirm_new_pin'.tr)
            : (widget.title ?? 'create_pin'.tr);
        subtitle = widget.subtitle ?? '';
      }
    }

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
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildDotField() {
    final controller = _getActiveController();
    final len = controller.text.length;

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
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
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
  }) {
    final pressed = _pressedButton == id;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 74,
        height: 74,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: pressed ? Colors.white.withOpacity(0.28) : Colors.transparent,
          border: showBorder
              ? Border.all(color: Colors.white54, width: 1.5)
              : null,
        ),
        child: child,
      ),
    );
  }

  Widget _buildNumpad() {
    Widget num(int n) => _buildNumpadButton(
      child: Text(
        '$n',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () => _onNumberTap(n),
      id: '$n',
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
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
              onTap: () {
                _onClear();
              },
              id: 'clear',
              showBorder: false,
            ),
            num(0),
            _buildNumpadButton(
              child: const Icon(Icons.backspace_outlined, color: Colors.white),
              onTap: _onBackspace,
              id: 'backspace',
              showBorder: false,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E6B63),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildDotField(),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildNumpad(),
                  const SizedBox(height: 18),
                ],
              ),
              if (_loading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black38,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
