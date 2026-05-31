import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/settings/update_profile_controller.dart';
import 'package:mobilepenpal/presentation/widgets/loading_status.dart';

class UpdateProfilePage extends StatelessWidget {
  UpdateProfilePage({super.key});

  final UpdateProfileController controller = Get.put(UpdateProfileController());

  static const Color _brand = Color(0xFF00897B);
  static const Color _dark = Color(0xFF1A1A2E);
  static const Color _bg = Color(0xFFF5F6FA);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.showLoadingStatus.value) {
        return LoadingStatus(
          isLoading: controller.isLoading.value,
          isSuccess:
              !controller.isLoading.value && controller.errorMessage.isEmpty,
          onButtonPressed: () {
            if (controller.errorMessage.isEmpty) {
              Get.back();
            } else {
              controller.showLoadingStatus.value = false;
            }
          },
        );
      }

      return Scaffold(
        backgroundColor: _bg,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Obx(() {
                  if (!controller.isInitialized.value) {
                    return Center(
                      child: CircularProgressIndicator(color: _brand),
                    );
                  }
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildForm(context),
                  );
                }),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ─── Header ─────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double headerHeight = 56 + statusBarHeight;

    return Stack(
      children: [
        // Gradient background
        Container(
          height: headerHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00897B), Color(0xFF00695C)],
            ),
          ),
          child: Stack(
            children: [
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
              'update_information'.tr,
              style: TextStyle(
                fontSize: Get.locale?.languageCode == 'km' ? 20 : 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: Get.locale?.languageCode == 'km' ? 0.0 : -0.3,
              ),
            ),
          ),
        ),

        // Back button
        Positioned(
          top: statusBarHeight + 4,
          left: 8,
          child: _BackButton(),
        ),
      ],
    );
  }

  // ─── Form Body ──────────────────────────────────────────────────────
  Widget _buildForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        children: [
          // Error banner
          Obx(
            () => controller.errorMessage.isNotEmpty
                ? _buildErrorBanner()
                : const SizedBox.shrink(),
          ),

          // Personal Information section
          _buildSectionLabel('personal_information'.tr),
          const SizedBox(height: 10),
          _FormCard(
            children: [
              _buildTextField(
                icon: Icons.person_outline_rounded,
                iconColor: _brand,
                label: 'first_name'.tr,
                hintText: 'enter_first_name'.tr,
                initialValue: controller.firstName.value,
                onChanged: (v) => controller.firstName.value = v,
                validator: controller.validateFirstName,
                required: true,
              ),
              const _CardDivider(),
              _buildTextField(
                icon: Icons.badge_outlined,
                iconColor: const Color(0xFF5C6BC0),
                label: 'last_name'.tr,
                hintText: 'enter_last_name'.tr,
                initialValue: controller.lastName.value,
                onChanged: (v) => controller.lastName.value = v,
                validator: controller.validateLastName,
              ),
              const _CardDivider(),
              _buildTextField(
                icon: Icons.emoji_emotions_outlined,
                iconColor: const Color(0xFFEF6C00),
                label: 'nickname'.tr,
                hintText: 'enter_nickname'.tr,
                initialValue: controller.nickname.value,
                onChanged: (v) => controller.nickname.value = v,
              ),
              const _CardDivider(),
              // Age and Gender row
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildCompactField(
                        icon: Icons.cake_outlined,
                        iconColor: const Color(0xFFE53935),
                        label: 'age'.tr,
                        hintText: 'enter_age'.tr,
                        initialValue: controller.age.value,
                        onChanged: (v) => controller.age.value = v,
                        validator: controller.validateAge,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactDropdown(
                        context: context,
                        icon: Icons.wc_outlined,
                        iconColor: const Color(0xFF8E24AA),
                        label: 'gender'.tr,
                        value: controller.gender.value.isEmpty
                            ? null
                            : controller.gender.value,
                        items: [
                          DropdownMenuItem(
                              value: 'male', child: Text('male'.tr)),
                          DropdownMenuItem(
                              value: 'female', child: Text('female'.tr)),
                          DropdownMenuItem(
                              value: 'other', child: Text('other'.tr)),
                        ],
                        onChanged: (v) =>
                            controller.gender.value = v ?? '',
                      ),
                    ),
                  ],
                ),
              ),
              const _CardDivider(),
              _buildDateTile(
                context: context,
                icon: Icons.calendar_today_outlined,
                iconColor: const Color(0xFF43A047),
                label: 'date_of_birth'.tr,
                hintText: 'yyyy-mm-dd'.tr,
                onTap: () => _selectDate(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Parent Information section
          _buildSectionLabel('parent_information'.tr),
          const SizedBox(height: 10),
          _FormCard(
            children: [
              _buildTextField(
                icon: Icons.supervisor_account_outlined,
                iconColor: const Color(0xFF1E88E5),
                label: 'parent_first_name'.tr,
                hintText: 'enter_parent_first_name'.tr,
                initialValue: controller.parentFirstName.value,
                onChanged: (v) =>
                    controller.parentFirstName.value = v,
              ),
              const _CardDivider(),
              _buildTextField(
                icon: Icons.family_restroom_outlined,
                iconColor: const Color(0xFF00ACC1),
                label: 'parent_last_name'.tr,
                hintText: 'enter_parent_last_name'.tr,
                initialValue: controller.parentLastName.value,
                onChanged: (v) =>
                    controller.parentLastName.value = v,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Additional Information section
          _buildSectionLabel('additional_information'.tr),
          const SizedBox(height: 10),
          _FormCard(
            children: [
              _buildTextField(
                icon: Icons.location_on_outlined,
                iconColor: const Color(0xFFEF6C00),
                label: 'address'.tr,
                hintText: 'enter_address'.tr,
                initialValue: controller.address.value,
                onChanged: (v) => controller.address.value = v,
                maxLines: 3,
              ),
            ],
          ),

          const SizedBox(height: 32),
          _buildSaveButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Error Banner ───────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: Color(0xFFE53935), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.errorMessage.value,
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: controller.clearError,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 16, color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Label ──────────────────────────────────────────────────
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

  // ─── Text Field inside a card tile ──────────────────────────────────
  Widget _buildTextField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String hintText,
    required String initialValue,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final bool isKhmer = Get.locale?.languageCode == 'km';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 54),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isKhmer ? 14 : 12,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                    letterSpacing: isKhmer ? 0.0 : -0.1,
                  ),
                ),
                if (required)
                  Text(' *',
                      style: TextStyle(
                          color: const Color(0xFFE53935),
                          fontSize: isKhmer ? 14 : 12,
                          fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment:
                maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              // Icon
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
              // Field
              Expanded(
                child: TextFormField(
                  initialValue: initialValue,
                  onChanged: onChanged,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _dark,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.25),
                      fontWeight: FontWeight.w400,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _brand, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFFE53935), width: 1.5),
                    ),
                  ),
                  validator: validator,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Compact Field (for Age inside Row) ─────────────────────────────
  Widget _buildCompactField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String hintText,
    required String initialValue,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final bool isKhmer = Get.locale?.languageCode == 'km';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isKhmer ? 14 : 12,
                fontWeight: FontWeight.w700,
                color: _dark,
                letterSpacing: isKhmer ? 0.0 : -0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _dark,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 13,
              color: Colors.black.withValues(alpha: 0.25),
              fontWeight: FontWeight.w400,
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF5F6FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _brand, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // ─── Compact Dropdown (for Gender inside Row) ───────────────────────
  Widget _buildCompactDropdown({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    final bool isKhmer = Get.locale?.languageCode == 'km';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isKhmer ? 14 : 12,
                fontWeight: FontWeight.w700,
                color: _dark,
                letterSpacing: isKhmer ? 0.0 : -0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items,
            onChanged: onChanged,
            hint: Text(
              'select_gender'.tr,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.25),
                fontWeight: FontWeight.w400,
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _dark,
            ),
            dropdownColor: Colors.white,
            menuMaxHeight: 200,
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: Colors.black.withValues(alpha: 0.35)),
          ),
        ),
      ],
    );
  }

  // ─── Date Tile ──────────────────────────────────────────────────────
  Widget _buildDateTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String hintText,
    required VoidCallback onTap,
  }) {
    final bool isKhmer = Get.locale?.languageCode == 'km';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 54),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isKhmer ? 14 : 12,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                    letterSpacing: isKhmer ? 0.0 : -0.1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
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
                    child: Obx(
                      () => Text(
                        controller.dateOfBirth.value.isEmpty
                            ? hintText
                            : controller.dateOfBirth.value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: controller.dateOfBirth.value.isEmpty
                              ? Colors.black.withValues(alpha: 0.25)
                              : _dark,
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Save Button ────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Obx(
      () => Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF00897B), Color(0xFF00695C)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _brand.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: controller.isLoading.value
                ? null
                : () async {
                    await controller.updateProfile();
                  },
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'save_changes'.tr,
                      style: TextStyle(
                        fontSize: Get.locale?.languageCode == 'km' ? 17 : 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: Get.locale?.languageCode == 'km' ? 0.0 : 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Date Picker ────────────────────────────────────────────────────
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    if (controller.dateOfBirth.value.isNotEmpty) {
      final DateTime? currentDate = DateTime.tryParse(
        controller.dateOfBirth.value,
      );
      if (currentDate != null) {
        initialDate = currentDate;
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      controller.updateDateOfBirth(picked);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Reusable Widgets
// ═══════════════════════════════════════════════════════════════════════════

/// Back button matching the setting page style.
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        onPressed: () => Get.back(),
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

/// A card that groups form fields together, matching SettingsCard style.
class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});
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

/// A thin fading gradient divider between tiles.
class _CardDivider extends StatelessWidget {
  const _CardDivider();

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
