import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';

class InputModal extends StatefulWidget {
  const InputModal({
    super.key,
    this.icon,
    required this.title,
    this.message,
    this.hintText,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.maxLength,
    this.inputFormatters,
    this.primaryText = 'OK',
    this.secondaryText = 'Cancel',
    this.primaryColor,
    this.primaryTextColor,
    this.secondaryTextColor,
    this.validator,
    this.onSubmitted,
    this.autofocus = true,
    this.uppercase = false,
    this.showCloseButton = true,
  });

  final Widget? icon;
  final String title;
  final String? message;

  final String? hintText;
  final String? initialValue;

  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  final String primaryText;
  final String secondaryText;

  final Color? primaryColor;
  final Color? primaryTextColor;
  final Color? secondaryTextColor;

  final String? Function(String value)? validator;

  final void Function(String value)? onSubmitted;

  final bool autofocus;
  final bool uppercase;
  final bool showCloseButton;

  @override
  State<InputModal> createState() => _InputModalState();
}

class _InputModalState extends State<InputModal> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  void _submit() {
    final raw = _controller.text;
    final value = widget.uppercase ? raw.trim().toUpperCase() : raw.trim();

    final err = widget.validator?.call(value);
    if (err != null && err.isNotEmpty) {
      setState(() => _error = err);
      return;
    }

    Get.back(result: value.isEmpty ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pColor = widget.primaryColor ?? AppColors.primary;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                if (widget.showCloseButton)
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => Get.back(result: null),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.close_rounded, size: 20),
                      ),
                    ),
                  ),

                if (widget.icon != null) ...[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: pColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: widget.icon,
                  ),
                  const SizedBox(height: 12),
                ],

                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111827),
                  ),
                ),

                if (widget.message != null && widget.message!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B7280),
                      height: 1.35,
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                TextField(
                  controller: _controller,
                  autofocus: widget.autofocus,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  maxLength: widget.maxLength,
                  inputFormatters: widget.inputFormatters,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (v) {
                    widget.onSubmitted?.call(v);
                    _submit();
                  },
                  decoration: InputDecoration(
                    isDense: true, // ✅ tighter
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    hintText: widget.hintText,
                    counterText: '',
                    errorText: _error,
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: pColor, width: 1.4),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                widget.secondaryTextColor ??
                                const Color(0xFF111827),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Get.back(result: null),
                          child: Text(
                            widget.secondaryText,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pColor,
                            foregroundColor:
                                widget.primaryTextColor ?? Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _submit,
                          child: Text(
                            widget.primaryText,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
