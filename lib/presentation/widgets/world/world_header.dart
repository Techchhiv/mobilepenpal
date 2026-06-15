import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/localization/locale_controller.dart';
import 'package:mobilepenpal/data/controllers/world/world_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class WorldHeader extends StatelessWidget {
  const WorldHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final WorldController worldController = Get.find<WorldController>();

    return Obx(() {
      final world = worldController.currentWorld.value;
      if (world == null) return const SizedBox();

      return GetBuilder<LocaleController>(
        builder: (lc) {
          final title = lc.isKhmer
              ? world.name
              : ((world.nameEn.isNotEmpty) ? world.nameEn : world.name);

          return Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildBackButton(),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildWorldIcon(),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          final canPop = Get.key.currentState?.canPop() == true;
          if (canPop) {
            Get.back();
          } else {
            Get.offAllNamed(AppRoutes.home);
          }
        },
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildWorldIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.book,
        color: Colors.white.withValues(alpha: 0.7),
        size: 24,
      ),
    );
  }
}
