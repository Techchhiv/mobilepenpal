import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/presentation/screens/home/qr_scanner_page.dart';
import 'package:mobilepenpal/presentation/widgets/home/parent_summary_page.dart';
import 'package:shimmer/shimmer.dart';

class ParentHome extends StatelessWidget {
  final HomeController homeController;

  const ParentHome({super.key, required this.homeController});

  static const Color _brand = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      init: homeController,
      initState: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (homeController.dailySummary.value == null &&
              !homeController.isSummaryLoading.value) {
            homeController.fetchDailySummary();
          }

          if (homeController.currentClassroom.value == null &&
              !homeController.isClassroomLoading.value) {
            await homeController.fetchCurrentClassroom();
          }
        });
      },
      builder: (_) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildTopActionsRow(),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                color: _brand,
                onRefresh: () async {
                  await homeController.refreshHome();
                },
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildClassroomSection(),
                      const SizedBox(height: 24),
                      ParentSummaryCard(homeController: homeController),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopActionsRow() {
    return Row(
      children: [
        _buildTopActionBox(
          icon: Icons.settings,
          label: 'setting'.tr,
          onTap: () => Get.toNamed('/setting'),
        ),
        _buildTopActionBox(
          icon: Icons.bar_chart_outlined,
          label: 'reports'.tr,
          onTap: () => Get.toNamed('/parent/report'),
        ),
        _buildTopActionBox(
          icon: Icons.qr_code,
          label: 'scan'.tr,
          onTap: () async {
            if (homeController.isJoiningClassroom.value) return;

            final result = await Get.to(() => const QrScannerPage());

            if (result != null) {
              await homeController.joinClassroomByCode(result.toString());
            }
          },
        ),
      ],
    );
  }

  Widget _buildClassroomSection() {
    return Obx(() {
      final loading = homeController.isClassroomLoading.value;
      final classroom = homeController.currentClassroom.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'classroom'.tr,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          if (loading && classroom == null)
            _ClassroomShimmerCard()
          else if (classroom == null)
            _buildEmptyClassroomCard()
          else
            _buildCurrentClassroomCard(
              name: classroom.name,
              teacherName: classroom.teacherName ?? '—',
              studentsCount: classroom.studentsCount,
              isActive: classroom.isActive,
              enrolledAt: classroom.enrolledAt,
              onTap: () {
                Get.toNamed('/classroom/${classroom.id}');
              },
            ),
        ],
      );
    });
  }

  Widget _buildEmptyClassroomCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: _brand,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'no_classroom_yet'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'join_classroom_desc'.tr,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final code = await _showJoinCodeDialog();
                    if (code != null && code.trim().isNotEmpty) {
                      await homeController.joinClassroomByCode(code);
                    }
                  },
                  icon: const Icon(Icons.keyboard_rounded, size: 18),
                  label: Text('enter_code'.tr),
                  style: FilledButton.styleFrom(
                    backgroundColor: _brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    if (homeController.isJoiningClassroom.value) return;
                    final result = await Get.to(() => const QrScannerPage());
                    if (result != null) {
                      await homeController.joinClassroomByCode(
                        result.toString(),
                      );
                    }
                  },
                  icon: const Icon(Icons.qr_code_rounded, size: 18),
                  label: Text('scan'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _brand,
                    side: BorderSide(color: _brand.withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentClassroomCard({
    required String name,
    required String teacherName,
    required int studentsCount,
    required bool isActive,
    required DateTime? enrolledAt,
    required VoidCallback onTap,
  }) {
    final subtitle = '$teacherName  •  $studentsCount ${'student'.tr}';
    final joinedText = enrolledAt == null
        ? null
        : '${'joined'.tr}: ${enrolledAt.year.toString().padLeft(4, '0')}-${enrolledAt.month.toString().padLeft(2, '0')}-${enrolledAt.day.toString().padLeft(2, '0')}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 56,
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 12),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (joinedText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        joinedText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showJoinCodeDialog() {
    final controller = TextEditingController();

    return Get.dialog<String?>(
      Builder(
        builder: (context) => AlertDialog(
          title: Text('enter_code'.tr),
          content: TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'example_code'.tr,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text('join'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopActionBox({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 74,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: _brand, size: 26),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassroomShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget box({required double h, double? w, double r = 12}) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(r),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          box(h: 44, w: 44, r: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(h: 16, w: 160, r: 10),
                const SizedBox(height: 10),
                box(h: 12, w: 220, r: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
