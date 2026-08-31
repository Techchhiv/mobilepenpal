import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF232A3B), width: 2.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 18, right: 18, top: 12, bottom: 16),
      child: SafeArea(
        top: false,
        child: Obx(() {
          final isParent = currentMode.value == 'parent';
          final isStudent = currentMode.value == 'student';

          return Row(
            children: [
              Expanded(
                child: _buildRoleTab(
                  label: 'parent'.tr,
                  icon: Icons.groups_rounded,
                  isActive: isParent,
                  onTap: () => onModeChanged('parent'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRoleTab(
                  label: 'student'.tr,
                  icon: Icons.school_rounded,
                  isActive: isStudent,
                  onTap: () => onModeChanged('student'),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRoleTab({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF087D85) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: isActive
              ? Border.all(color: const Color(0xFF232A3B), width: 1.5)
              : null,
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color(0xFF232A3B),
                    offset: Offset(0, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
