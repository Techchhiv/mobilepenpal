import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';

class ConfirmModal<T> extends StatelessWidget {
  const ConfirmModal({
    super.key,
    this.icon,
    this.title,
    this.message,
    this.body,
    this.primaryText = 'Confirm',
    this.secondaryText = 'Cancel',
    this.primaryColor,
    this.secondaryColor,
    this.primaryTextColor,
    this.secondaryTextColor,
    this.secondaryBorderColor,
    this.secondaryBackgroundColor,
    this.onPrimary,
    this.onSecondary,
    this.isLoading = false,
    this.showCloseButton = true,
    this.maxWidth = 360,

    this.primaryResult,
    this.secondaryResult,
  });

  final Widget? icon;
  final Widget? title;
  final Widget? message;
  final Widget? body;

  final String primaryText;
  final String secondaryText;

  final Color? primaryColor;
  final Color? secondaryColor;

  final Color? primaryTextColor;
  final Color? secondaryTextColor;
  final Color? secondaryBorderColor;
  final Color? secondaryBackgroundColor;

  final FutureOr<void> Function()? onPrimary;
  final FutureOr<void> Function()? onSecondary;

  final bool isLoading;
  final bool showCloseButton;
  final double maxWidth;

  final T? primaryResult;
  final T? secondaryResult;

  Future<void> _run(FutureOr<void> Function()? fn) async {
    if (fn == null) return;
    final r = fn();
    if (r is Future) await r;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pColor = primaryColor ?? AppColors.primary;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
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
                if (showCloseButton)
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: isLoading
                          ? null
                          : () => Get.back<T>(
                              result: secondaryResult,
                              closeOverlays: false,
                            ),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.close_rounded, size: 20),
                      ),
                    ),
                  ),

                if (icon != null) ...[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: pColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: icon,
                  ),
                  const SizedBox(height: 12),
                ],

                if (title != null) ...[
                  DefaultTextStyle(
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF111827),
                    ),
                    textAlign: TextAlign.center,
                    child: title!,
                  ),
                  const SizedBox(height: 8),
                ],

                if (message != null) ...[
                  DefaultTextStyle(
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: const Color(0xFF6B7280),
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                    child: message!,
                  ),
                  const SizedBox(height: 14),
                ],

                if (body != null) ...[body!, const SizedBox(height: 14)],

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                secondaryTextColor ??
                                (secondaryColor ?? const Color(0xFF111827)),
                            backgroundColor: secondaryBackgroundColor,
                            side: BorderSide(
                              color:
                                  secondaryBorderColor ??
                                  const Color(0xFFE5E7EB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  await _run(onSecondary);
                                  Get.back<T>(
                                    result: secondaryResult,
                                    closeOverlays: false,
                                  );
                                },
                          child: Text(
                            secondaryText,
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
                            foregroundColor: primaryTextColor ?? Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  await _run(onPrimary);
                                  Get.back<T>(
                                    result: primaryResult,
                                    closeOverlays: false,
                                  );
                                },
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  primaryText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
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

Future<T?> showConfirmModal<T>({
  required Widget modal,
  bool dismissible = true,
  Color barrierColor = const Color(0xB3000000),
}) {
  return Get.dialog<T>(
    modal,
    barrierDismissible: dismissible,
    barrierColor: barrierColor,
  );
}
