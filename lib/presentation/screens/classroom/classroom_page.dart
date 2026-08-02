import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/classroom/classroom_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';
import 'package:mobilepenpal/data/models/classroom/classroom_detail.dart';

class ClassroomPage extends GetView<ClassroomController> {
  final int classroomId;

  const ClassroomPage({super.key, required this.classroomId});

  static const Color _brand = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('classroom'.tr),
      ),
      body: Obx(() {
        final loading = c.isLoading.value;
        final detail = c.detail.value;
        final err = c.errorText.value;

        if (loading && detail == null) {
          return const Center(
            child: CircularProgressIndicator(color: _brand),
          );
        }

        if (detail == null) {
          return Center(
            child: Text('no_classroom_details'.tr, style: const TextStyle(color: Colors.black54)),
          );
        }

        return RefreshIndicator(
          color: _brand,
          onRefresh: () async => c.fetchDetail(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _HeaderCard(detail: detail),

              const SizedBox(height: 14),

              _sectionTitle('classmates'.tr),
              const SizedBox(height: 10),

              if (err.isNotEmpty)
                _errorBox(err, onRetry: c.fetchDetail),

              _ClassmateList(classmates: detail.classmates),
            ],
          ),
        );
      }),
    );
  }

  Widget _sectionTitle(String t) {
    return Text(
      t,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Colors.black87,
      ),
    );
  }

  Widget _errorBox(String msg, {required Future<void> Function() onRetry}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _brand),
              onPressed: () => onRetry(),
              child: Text('retry'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final ClassroomDetail detail;

  const _HeaderCard({required this.detail});

  static const Color _brand = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    final teacherName = detail.teacher?.name ?? '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.school_rounded, color: _brand, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${'teacher'.tr}: $teacherName',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${detail.studentsCount} ${'student'.tr}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: detail.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  detail.isActive ? 'active'.tr : 'archived'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: detail.isActive ? Colors.green[700] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClassmateList extends StatelessWidget {
  final List<Classmate> classmates;

  const _ClassmateList({required this.classmates});

  @override
  Widget build(BuildContext context) {
    if (classmates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text('no_classmates_yet'.tr, style: const TextStyle(color: Colors.black54)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: classmates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final item = classmates[idx];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: ClipOval(
                  child: _buildClassmateAvatar(item.avatar),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'enrolled'.tr,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClassmateAvatar(String? avatar) {
    if (avatar != null && avatar.isNotEmpty) {
      if (avatar.startsWith('assets/')) {
        return Image.asset(avatar, fit: BoxFit.cover);
      }
      if (avatar.startsWith('http')) {
        return Image.network(
          avatar,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: AppColors.primary),
        );
      }

      // Check if avatar string matches a shop avatar ID
      if (Get.isRegistered<ShopController>()) {
        final shopCtrl = Get.find<ShopController>();
        final matchedAvatar = shopCtrl.allAvatars.firstWhereOrNull((a) => a.id == avatar);
        if (matchedAvatar?.assetPath != null) {
          return Image.asset(matchedAvatar!.assetPath!, fit: BoxFit.cover);
        }
      }
    }

    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      final shopAvatar = homeController.currentShopAvatar;
      if (shopAvatar?.assetPath != null) {
        return Image.asset(shopAvatar!.assetPath!, fit: BoxFit.cover);
      }
    }

    return const Icon(Icons.person_rounded, color: AppColors.primary);
  }
}
