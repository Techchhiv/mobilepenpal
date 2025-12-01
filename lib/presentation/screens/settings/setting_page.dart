import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/settings/setting_controller.dart';
import 'package:mobilepenpal/data/controllers/home/pin_controller.dart';
import 'package:mobilepenpal/presentation/screens/settings/change_password_page.dart';
import 'package:mobilepenpal/presentation/screens/settings/update_profile_page.dart';
import 'package:mobilepenpal/presentation/widgets/pin_entry_widget.dart';

class SettingPage extends StatelessWidget {
  SettingPage({super.key});

  final settingController = Get.find<SettingController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: InkWell(
          onTap: () => Get.offAllNamed('/home'),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
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
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Row(
              children: [
                Obx(() {
                  return GestureDetector(
                    onTap: () {
                      settingController.pickAndUploadImage();
                    },
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
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[300],
                            backgroundImage:
                                settingController.avatarUrl.isNotEmpty
                                ? NetworkImage(
                                        Env.backendUrl +
                                            settingController.avatarUrl,
                                      )
                                      as ImageProvider
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
                  );
                }),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settingController.currentMode.value == 'student'
                          ? settingController.fullName
                          : settingController.parentName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      settingController.currentMode.value == 'student'
                          ? 'student'.tr
                          : 'parent'.tr,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 30),

            if (settingController.currentMode.value == 'parent') ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'profile'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 15),
              _buildSettingTile(
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
              ),
              SizedBox(height: 15),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'protection'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 15),

            _buildSettingTile(
              icon: Icons.notifications_outlined,
              title: 'បើកជូនដំណឹងរបស់មេ',
            ),
            SizedBox(height: 15),

            if (settingController.currentMode.value == 'parent') ...[
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
              SizedBox(height: 15),
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
              SizedBox(height: 15),
            ],

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
            SizedBox(height: 15),

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
        ),
      ),
    );
  }

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
          borderRadius: BorderRadius.all(Radius.circular(8)),
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
