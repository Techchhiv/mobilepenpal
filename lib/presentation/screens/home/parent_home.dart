import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/presentation/widgets/home/parent_summary_page.dart';

class ParentHome extends StatelessWidget {
  final HomeController homeController;

  const ParentHome({super.key, required this.homeController});

  static const Color _brand = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      init: homeController,
      initState: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (homeController.dailySummary.value == null &&
              !homeController.isSummaryLoading.value) {
            homeController.fetchDailySummary();
          }
        });
      },
      builder: (_) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopActionsRow(),
            const SizedBox(height: 24),
            // _buildChildProgressSection(),
            // const SizedBox(height: 24),
            ParentSummaryCard(homeController: homeController),
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
          label: 'ការកំណត់',
          onTap: () {},
        ),
        _buildTopActionBox(
          icon: Icons.bar_chart_outlined,
          label: 'របាយការណ៍',
          onTap: () => Get.toNamed('/parent/report'),
        ),
        _buildTopActionBox(
          icon: Icons.calendar_today_outlined,
          label: 'កាលវិភាគ',
          onTap: () {},
        ),
      ],
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

  Widget _buildChildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ដំណើរការរបស់សិស្ស",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
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
          ),
          child: const Text("...keep your current child progress UI..."),
        ),
      ],
    );
  }
}
