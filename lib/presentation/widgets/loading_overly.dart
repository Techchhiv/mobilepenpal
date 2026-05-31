import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Widget? header;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,

        if (isLoading)
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    header ??
                        SizedBox(
                          width: 320,
                          height: 320,
                          child: Lottie.asset(
                            "assets/animated/loading_paperplan.json",
                            repeat: true,
                            animate: true,
                          ),
                        ),

                    Transform.translate(
                      offset: const Offset(0, -64),
                      child: Text(
                        "loading".tr,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.none,
                          height: 1.0,
                          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                          fontFamilyFallback: Theme.of(context).textTheme.bodyMedium?.fontFamilyFallback,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
