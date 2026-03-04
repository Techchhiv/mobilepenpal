import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';

class ModeSwitcher extends StatelessWidget {
  final RxString currentMode;
  final Function(String) onModeChanged;

  const ModeSwitcher({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Color(0x056E6D66).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(25),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Obx(
            () => Stack(
              children: [
                AnimatedAlign(
                  alignment: currentMode.value == 'parent'
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Container(
                    width: constraints.maxWidth * 0.5,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(21),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onModeChanged('parent'),
                        child: Container(
                          color: Colors.transparent,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.family_restroom,
                                color: currentMode.value == 'parent'
                                    ? AppColors.textWhiteOff
                                    : Colors.grey[600],
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'parent'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: currentMode.value == 'parent'
                                      ? AppColors.textWhiteOff
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onModeChanged('student'),
                        child: Container(
                          color: Colors.transparent,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school,
                                color: currentMode.value == 'student'
                                    ? AppColors.textWhiteOff
                                    : Colors.grey[600],
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'student'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: currentMode.value == 'student'
                                      ? AppColors.textWhiteOff
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
