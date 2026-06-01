import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/home/pin_controller.dart';
import 'package:mobilepenpal/data/controllers/settings/setting_controller.dart';
import 'package:mobilepenpal/presentation/screens/settings/change_password_page.dart';
import 'package:mobilepenpal/presentation/screens/settings/update_profile_page.dart';
import 'package:mobilepenpal/presentation/widgets/home/pin_entry_widget.dart';

class SettingPage extends StatelessWidget {
  SettingPage({super.key});

  final settingController = Get.find<SettingController>();

  static const Color _brand = Color(0xFF00897B);
  static const Color _brandLight = Color(0xFF26A69A);
  static const Color _dark = Color(0xFF1A1A2E);

  bool get _isParentMode => settingController.currentMode.value == 'parent';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Obx(
        () => Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    children: [
                      _buildProfileCard(),
                      const SizedBox(height: 24),
                      if (_isParentMode) ...[
                      _buildSectionLabel('profile'.tr),
                      const SizedBox(height: 10),
                      _SettingsCard(
                        children: [
                          _SettingsTile(
                            icon: Icons.person_outline_rounded,
                            iconColor: _brand,
                            title: 'update_information'.tr,
                            onTap: () =>
                                Get.to(() => UpdateProfilePage()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionLabel('protection'.tr),
                      const SizedBox(height: 10),
                    ],

                    if (!_isParentMode) ...[
                      const SizedBox(height: 0),
                    ],

                    _SettingsCard(
                      children: [
                        if (_isParentMode) ...[
                          _SettingsTile(
                            icon: Icons.pin_outlined,
                            iconColor: const Color(0xFF5C6BC0),
                            title: 'change_parent_pin'.tr,
                            onTap: () {
                              Get.to(
                                () => PinWidget(
                                  mode:
                                      settingController.parentPin.isEmpty
                                          ? PinMode.create
                                          : PinMode.update,
                                  title: 'update_parent_pin'.tr,
                                  returnToSettings: true,
                                ),
                              );
                            },
                          ),
                          const _TileDivider(),
                          _SettingsTile(
                            icon: Icons.lock_outline_rounded,
                            iconColor: const Color(0xFFEF6C00),
                            title: 'change_password'.tr,
                            onTap: () =>
                                Get.to(() => ChangePasswordPage()),
                          ),
                          const _TileDivider(),
                          Obx(
                            () => _SettingsTile(
                              icon: Icons.shield_outlined,
                              iconColor: const Color(0xFF43A047),
                              title: 'require_parent_pin'.tr,
                              trailing: _BrandSwitch(
                                value: settingController
                                    .isParentPinRequired.value,
                                onChanged: (val) {
                                  settingController
                                      .setParentPinRequired(val);
                                },
                              ),
                              onTap: () {
                                final current = settingController
                                    .isParentPinRequired.value;
                                settingController
                                    .setParentPinRequired(!current);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionLabel('settings'.tr),
                    const SizedBox(height: 10),
                    _SettingsCard(
                      children: [
                        GetBuilder<SettingController>(
                          id: 'lang',
                          builder: (_) {
                            final current =
                                Get.locale ?? const Locale('en', 'US');
                            final isKh =
                                current.languageCode.toLowerCase() ==
                                    'km';

                            return _SettingsTile(
                              icon: Icons.language_rounded,
                              iconColor: const Color(0xFF1E88E5),
                              title: 'language'.tr,
                              trailing: _LanguageBadge(isKh: isKh),
                              onTap: () {
                                final next = isKh
                                    ? const Locale('en', 'US')
                                    : const Locale('km', 'KH');

                                settingController.localeController
                                    .changeLocale(next);
                                settingController.update(['lang']);
                              },
                            );
                          },
                        ),
                        const _TileDivider(),
                        _SettingsTile(
                          icon: Icons.logout_rounded,
                          iconColor: const Color(0xFFE53935),
                          title: 'logout_acc'.tr,
                          onTap: () => settingController.logout(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // ─── Header Widget ────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double headerHeight = 56 + statusBarHeight;

    return Stack(
      children: [
        // Background gradient
        Container(
          height: headerHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF00897B),
                Color(0xFF00695C),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Subtle decorative circles
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: 5,
                left: -30,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Title (Centered)
        Positioned(
          top: statusBarHeight,
          bottom: 0,
          left: 56,
          right: 56,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              'settings'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: Get.locale?.languageCode == 'km' ? 0.0 : -0.3,
              ),
            ),
          ),
        ),

        // Back Button
        Positioned(
          top: statusBarHeight + 4,
          left: 8,
          child: _BackButton(),
        ),
      ],
    );
  }

  // ─── Profile Card ─────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with gradient ring
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00897B), Color(0xFF26A69A)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _brand.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFE0F2F1),
              child: Icon(
                Icons.person_rounded,
                size: 36,
                color: _brand.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isParentMode
                        ? settingController.parentName
                        : settingController.fullName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _dark,
                      letterSpacing: Get.locale?.languageCode == 'km' ? 0.0 : -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _brand.withValues(alpha: 0.12),
                          _brandLight.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isParentMode ? 'parent'.tr : 'student'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _brand,
                        letterSpacing: Get.locale?.languageCode == 'km' ? 0.0 : 0.3,
                      ),
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

  // ─── Section Label ────────────────────────────────────────────────
  Widget _buildSectionLabel(String title) {
    final bool isKhmer = Get.locale?.languageCode == 'km';
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: isKhmer ? 14 : 12,
            fontWeight: FontWeight.w800,
            color: Colors.black.withValues(alpha: 0.35),
            letterSpacing: isKhmer ? 0.0 : 1.2,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Reusable Widgets
// ═══════════════════════════════════════════════════════════════════════

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        onPressed: () {
          final canPop = Get.key.currentState?.canPop() ?? false;
          if (canPop) {
            Get.back();
          } else {
            Get.offAllNamed('/home');
          }
        },
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// A card that groups multiple [_SettingsTile] items together.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  static const Color _brand = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Gradient accent bar
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF00897B),
                    Color(0xFF26A69A),
                    Color(0xFF4DB6AC),
                  ],
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A single settings row with icon, label, and optional trailing widget.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Gradient-tinted icon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                    letterSpacing: Get.locale?.languageCode == 'km' ? 0.0 : -0.1,
                  ),
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Colors.black.withValues(alpha: 0.25),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A thin fading gradient divider between tiles.
class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.06),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

/// A small language badge showing "EN" or "KH".
class _LanguageBadge extends StatelessWidget {
  const _LanguageBadge({required this.isKh});
  final bool isKh;

  static const Color _brand = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _brand.withValues(alpha: 0.12),
            _brand.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _brand.withValues(alpha: 0.15)),
      ),
      child: Text(
        isKh ? "KH" : "EN",
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: _brand,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// A brand-colored switch widget.
class _BrandSwitch extends StatelessWidget {
  const _BrandSwitch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  static const Color _brand = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: _brand,
          activeTrackColor: _brand.withValues(alpha: 0.30),
          inactiveThumbColor: Colors.grey[400],
          inactiveTrackColor: Colors.grey[300],
        ),
      ),
    );
  }
}
