import 'package:flutter/material.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';

class LoadingModal extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color loadingColor;
  final double opacity;
  final bool isSuccess;
  final VoidCallback? onSuccessComplete;

  const LoadingModal({
    super.key,
    this.message = 'Loading',
    this.backgroundColor = AppColors.primary,
    this.loadingColor = Colors.white,
    this.opacity = 1,
    this.isSuccess = false,
    this.onSuccessComplete,
  });

  @override
  State<LoadingModal> createState() => _LoadingModalState();
}

class _LoadingModalState extends State<LoadingModal> {
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    if (widget.isSuccess) {
      _showSuccess = true;
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          widget.onSuccessComplete?.call();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: AppColors.primary.withOpacity(widget.opacity),
        child: Center(
          child: Container(
            width: 140,
            height: 140,
            // decoration: BoxDecoration(
              // color: widget.backgroundColor,
              // borderRadius: BorderRadius.circular(16),
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.black.withOpacity(0.3),
              //     blurRadius: 20,
              //     offset: const Offset(0, 8),
              //   ),
              // ],
            // ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_showSuccess)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 30,
                    ),
                  )
                else
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(widget.loadingColor),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  _showSuccess ? 'Success!' : widget.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.loadingColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}