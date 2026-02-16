import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/world/world_controller.dart';
import 'package:mobilepenpal/data/models/world/world.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';
import 'package:mobilepenpal/presentation/widgets/world/world_header.dart';
import 'package:mobilepenpal/presentation/widgets/world/world_map.dart';

class WorldDetailPage extends StatelessWidget {
  const WorldDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final WorldController worldController = Get.find<WorldController>();
    return Scaffold(
      body: Obx(
        () => LoadingOverlay(
          isLoading:
              worldController.isLoading.value ||
              worldController.isNavigatingToLevel.value,
          child: _WorldDetailContent(),
        ),
      ),
    );
  }
}

class _WorldDetailContent extends StatelessWidget {
  final WorldController worldController = Get.find<WorldController>();

  @override
  Widget build(BuildContext context) {
    final String? idString = Get.parameters['id'];
    final int worldId = int.tryParse(idString ?? '') ?? 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = worldController.currentWorld.value;
      if (worldId > 0 && (current == null || current.id != worldId)) {
        worldController.fetchWorldById(worldId);
      }
    });

    return Obx(() {
      final world = worldController.currentWorld.value;

      if (world != null) {
        return _buildSuccessState(world);
      }

      if (worldController.isLoading.value) {
        return const SizedBox.shrink();
      }

      return _buildErrorState(worldId);
    });
  }

  Widget _buildErrorState(int worldId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('World not found', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => worldController.fetchWorldById(worldId),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(World world) {
    return Stack(
      children: [
        Positioned.fill(child: WorldMap(world: world)),
        const WorldHeader(),
      ],
    );
  }
}
