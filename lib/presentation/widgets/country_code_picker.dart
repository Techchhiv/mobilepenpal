import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/models/country_code.dart';

class CountryCodePicker extends StatelessWidget {
  final Rx<CountryCode> selectedCountry;
  final ValueChanged<CountryCode>? onChanged;
  final bool enabled;

  const CountryCodePicker({
    super.key,
    required this.selectedCountry,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => InkWell(
        onTap: enabled ? () => _showCountryPicker(context) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedCountry.value.flag,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 4),
              Text(
                selectedCountry.value.dialCode,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: enabled ? const Color(0xFF1A1A2E) : Colors.grey[500],
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 18,
                color: enabled ? Colors.grey[700] : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    final searchController = TextEditingController();
    final filteredCountries = RxList<CountryCode>(CountryCode.allCountries);
    final isKhmer = Get.locale?.languageCode == 'km';

    void filter(String query) {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) {
        filteredCountries.assignAll(CountryCode.allCountries);
        return;
      }
      filteredCountries.assignAll(
        CountryCode.allCountries.where((c) {
          final nameMatch = c.name.toLowerCase().contains(q);
          final codeMatch = c.code.toLowerCase().contains(q);
          final dialMatch = c.dialCode.replaceAll('+', '').contains(q.replaceAll('+', ''));
          return nameMatch || codeMatch || dialMatch;
        }),
      );
    }

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'select_country'.tr,
                    style: TextStyle(
                      fontSize: isKhmer ? 18 : 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: TextField(
                controller: searchController,
                onChanged: filter,
                autofocus: false,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'search_country'.tr,
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F5)),

            // Country List
            Expanded(
              child: Obx(
                () => ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredCountries.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    thickness: 0.8,
                    indent: 64,
                    color: Color(0xFFF0F2F5),
                  ),
                  itemBuilder: (context, index) {
                    final country = filteredCountries[index];
                    final isSelected = selectedCountry.value.code == country.code;

                    return InkWell(
                      onTap: () {
                        selectedCountry.value = country;
                        if (onChanged != null) {
                          onChanged!(country);
                        }
                        Get.back();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Text(
                              country.flag,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                country.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : const Color(0xFF1A1A2E),
                                ),
                              ),
                            ),
                            Text(
                              country.dialCode,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.primary : Colors.grey[600],
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
