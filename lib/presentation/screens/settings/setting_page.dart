import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/home/pin_controller.dart';
import 'package:mobilepenpal/data/controllers/settings/setting_controller.dart';
import 'package:mobilepenpal/presentation/screens/settings/change_password_page.dart';
import 'package:mobilepenpal/presentation/screens/settings/update_profile_page.dart';
import 'package:mobilepenpal/presentation/widgets/pin_entry_widget.dart';

class SettingPage extends StatelessWidget {
  SettingPage({super.key});

  final settingController = Get.find<SettingController>();

  bool get _isParentMode => settingController.currentMode.value == 'parent';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Obx(
        () => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ListView(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 30),

              if (_isParentMode) ...[
                _buildSectionTitle('profile'.tr),
                const SizedBox(height: 15),
                _buildProfileSection(),
                const SizedBox(height: 24),
                _buildSectionTitle('protection'.tr),
                const SizedBox(height: 15),
              ],
              _buildProtectionSection(),
              const SizedBox(height: 24),

              _buildSectionTitle('settings'.tr),
              const SizedBox(height: 15),
              _buildGeneralSection(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: InkWell(
        onTap: () => Get.offAllNamed('/home'),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              'back'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Obx(
          () => GestureDetector(
            onTap: () => settingController.pickAndUploadImage(),
            child: Stack(
              children: [
                if (settingController.isLoading.value)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                else
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: settingController.avatarUrl.isNotEmpty
                        ? NetworkImage(
                            Env.backendUrl + settingController.avatarUrl,
                          )
                        : null,
                    child: settingController.avatarUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          )
                        : null,
                  ),
                if (!settingController.isLoading.value)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isParentMode
                    ? settingController.parentName
                    : settingController.fullName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isParentMode ? 'parent'.tr : 'student'.tr,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return _buildSettingTile(
      icon: Icons.person_outline,
      title: 'update_information'.tr,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.black,
      ),
      onTap: () {
        Get.to(() => UpdateProfilePage());
      },
    );
  }

  Widget _buildProtectionSection() {
    return Column(
      children: [
        if (_isParentMode) ...[
          _buildSettingTile(
            icon: Icons.pin_outlined,
            title: 'change_parent_pin'.tr,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black,
            ),
            onTap: () {
              Get.to(
                () => PinWidget(
                  mode: settingController.parentPin.isEmpty
                      ? PinMode.create
                      : PinMode.update,
                  title: 'update_parent_pin'.tr,
                  returnToSettings: true,
                ),
              );
            },
          ),
          const SizedBox(height: 15),
          _buildSettingTile(
            icon: Icons.lock,
            title: 'change_password'.tr,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black,
            ),
            onTap: () {
              Get.to(() => ChangePasswordPage());
            },
          ),
          const SizedBox(height: 15),
          Obx(
            () => _buildSettingTile(
              icon: Icons.shield_outlined,
              title: 'require_parent_pin'.tr,
              trailing: SizedBox(
                height: double.minPositive,
                child: Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: settingController.isParentPinRequired.value,
                    onChanged: (val) {
                      settingController.setParentPinRequired(val);
                    },
                  ),
                ),
              ),
              onTap: () {
                final current = settingController.isParentPinRequired.value;
                settingController.setParentPinRequired(!current);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGeneralSection() {
    return Column(
      children: [
        _buildSettingTile(
          icon: Icons.settings_outlined,
          title: 'settings'.tr,
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.black,
          ),
          onTap: () {
            // Navigate to account settings
          },
        ),
        const SizedBox(height: 15),
        _buildSettingTile(
          icon: Icons.logout,
          title: 'logout_acc'.tr,
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.black,
          ),
          onTap: () {
            settingController.logout();
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Generic tile
  // ─────────────────────────────────────────────────────────────

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    Color backgroundColor = const Color(0xFFF2F2F7),
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.grey[700]),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
