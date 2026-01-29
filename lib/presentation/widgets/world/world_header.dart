import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/world/world_controller.dart';

class WorldHeader extends StatelessWidget {
  const WorldHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final WorldController worldController = Get.find<WorldController>();
    final world = worldController.currentWorld.value;

    if (world == null) return const SizedBox();

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      world.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      world.description,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              _buildWorldIcon(world.iconUrl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Get.offAllNamed('/home'),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildWorldIcon(String? iconUrl) {
    if (iconUrl == null || iconUrl.isEmpty) {
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

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          iconUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.school,
              color: Colors.white.withValues(alpha: 0.7),
              size: 24,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}
