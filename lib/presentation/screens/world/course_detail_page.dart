import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/world/level_controller.dart';
import 'package:mobilepenpal/data/controllers/world/world_controller.dart';
import 'package:mobilepenpal/data/models/world/world.dart';
import 'package:mobilepenpal/presentation/widgets/loading_overly.dart';
import 'package:mobilepenpal/presentation/widgets/world_header.dart';
import 'package:mobilepenpal/presentation/widgets/world_map.dart';

class CourseDetailPage extends StatelessWidget {
  CourseDetailPage({super.key});

  final LevelController levelController = Get.find<LevelController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => LoadingOverlay(
          isLoading: levelController.isLoading.value,
          child: _CourseDetailContent(),
        ),
      ),
    );
  }
}

class _CourseDetailContent extends StatelessWidget {
  final WorldController worldController = Get.find<WorldController>();

  @override
  Widget build(BuildContext context) {
    final String? idString = Get.parameters['id'];
    final int worldId = int.tryParse(idString ?? '') ?? 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = worldController.currentWorld.value;
      if (current == null || current.id != worldId) {
        worldController.fetchWorldById(worldId);
      }
    });

    return Obx(() {
      if (worldController.isLoading.value) {
        return _buildLoadingState();
      }

      final world = worldController.currentWorld.value;
      if (world == null) {
        return _buildErrorState(worldId);
      }

      return _buildSuccessState(world);
    });
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
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
        WorldMap(world: world),
        const WorldHeader(),
      ],
    );
  }
}
