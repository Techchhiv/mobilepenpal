import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/settings/update_profile_controller.dart';
import 'package:mobilepenpal/presentation/widgets/loading_status.dart';

class UpdateProfilePage extends StatelessWidget {
  UpdateProfilePage({super.key});

  final UpdateProfileController controller = Get.put(UpdateProfileController());

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
              Get.offAllNamed('/setting');
            } else {
              controller.showLoadingStatus.value = false;
            }
          },
        );
      }

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: InkWell(
            onTap: () => Get.offNamed('/setting'),
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
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Obx(() {
              if (!controller.isInitialized.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildForm(context);
            }),
          ),
        ),
      );
    });
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Obx(
            () => controller.errorMessage.isNotEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.errorMessage.value,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: controller.clearError,
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
          ),

          _buildSectionHeader('personal_information'.tr),
          _buildTextField(
            label: 'first_name'.tr,
            hintText: 'enter_first_name'.tr,
            initialValue: controller.firstName.value,
            onChanged: (value) => controller.firstName.value = value,
            validator: controller.validateFirstName,
            required: true,
          ),
          _buildTextField(
            label: 'last_name'.tr,
            hintText: 'enter_last_name'.tr,
            initialValue: controller.lastName.value,
            onChanged: (value) => controller.lastName.value = value,
            validator: controller.validateLastName,
          ),
          _buildTextField(
            label: 'nickname'.tr,
            hintText: 'enter_nickname'.tr,
            initialValue: controller.nickname.value,
            onChanged: (value) => controller.nickname.value = value,
          ),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'age'.tr,
                  hintText: 'age'.tr,
                  initialValue: controller.age.value,
                  onChanged: (value) => controller.age.value = value,
                  validator: controller.validateAge,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  context: context,
                  label: 'gender'.tr,
                  value: controller.gender.value.isEmpty
                      ? null
                      : controller.gender.value,
                  items: [
                    DropdownMenuItem(value: 'male', child: Text('male'.tr)),
                    DropdownMenuItem(value: 'female', child: Text('female'.tr)),
                    DropdownMenuItem(value: 'other', child: Text('other'.tr)),
                  ],
                  onChanged: (value) => controller.gender.value = value ?? '',
                ),
              ),
            ],
          ),
          _buildDateField(
            label: 'date_of_birth'.tr,
            hintText: 'yyyy-mm-dd'.tr,
            onTap: () => _selectDate(context),
          ),

          _buildSectionHeader('parent_information'.tr),
          _buildTextField(
            label: 'parent_first_name'.tr,
            hintText: 'enter_parent_first_name'.tr,
            initialValue: controller.parentFirstName.value,
            onChanged: (value) => controller.parentFirstName.value = value,
          ),
          _buildTextField(
            label: 'parent_last_name'.tr,
            hintText: 'enter_parent_last_name'.tr,
            initialValue: controller.parentLastName.value,
            onChanged: (value) => controller.parentLastName.value = value,
          ),

          // Additional Information
          _buildSectionHeader('additional_information'.tr),
          _buildTextField(
            label: 'address'.tr,
            hintText: 'enter_address'.tr,
            initialValue: controller.address.value,
            onChanged: (value) => controller.address.value = value,
            maxLines: 3,
          ),

          const SizedBox(height: 32),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required String initialValue,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              if (required)
                const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: initialValue,
            onChanged: onChanged,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onTap: onTap,
            readOnly: onTap != null,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: onTap != null
                  ? const Icon(Icons.calendar_today_outlined, size: 20)
                  : null,
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String hintText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => TextFormField(
              readOnly: true,
              onTap: onTap,
              decoration: InputDecoration(
                hintText: hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
              ),
              // This will make the field reactive
              controller: TextEditingController(
                text: controller.dateOfBirth.value,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              items: items,
              onChanged: onChanged,
              hint: Text('select_gender'.tr),
              dropdownColor: Colors.white,
              menuMaxHeight: 200,
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : () async {
                  await controller.updateProfile();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: controller.isLoading.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'save_changes'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

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
