import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/data/controllers/world/level_controller.dart';
import 'package:mobilepenpal/data/models/world/world_level.dart';
import 'package:mobilepenpal/data/models/world/world.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class WorldMap extends StatefulWidget {
  final World world;

  const WorldMap({super.key, required this.world});

  @override
  State<WorldMap> createState() => _WorldMapState();
}

class _WorldMapState extends State<WorldMap> {
  late ScrollController _scrollController;

  static const double _originalMapWidth = 1648.0;
  static const double _originalMapHeight = 4096.0;

  final List<Map<String, double>> _levelPositions = [
    {'x': 1002, 'y': 3703},
    {'x': 99, 'y': 3504},
    {'x': 1131, 'y': 3188},
    {'x': 128, 'y': 2749},
    {'x': 1131, 'y': 2381},
    {'x': 104, 'y': 1760},
    {'x': 1113, 'y': 1585},
    {'x': 163, 'y': 1046},
    {'x': 1025, 'y': 654},
    {'x': 233, 'y': 344},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollToCurrentLevel();
  }

  void _scrollToCurrentLevel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final levels = widget.world.levels;
      final targetIndex = _findCurrentLevelIndex(levels);

      final screenWidth = MediaQuery.of(context).size.width;
      final scaleFactor = screenWidth / _originalMapWidth;
      final double targetY = _levelPositions[targetIndex]['y']! * scaleFactor;

      final double targetPosition =
          targetY - (MediaQuery.of(context).size.height / 2);

      _scrollController.animateTo(
        targetPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  int _findCurrentLevelIndex(List<WorldLevel> levels) {
    for (int i = 0; i < levels.length; i++) {
      final level = levels[i];
      final bool isCompleted = level.completionPercentage >= 100;
      final bool isUnlocked = level.isUnlocked;

      if (isUnlocked && !isCompleted) {
        return i;
      }
    }
    return levels.length - 1;
  }

  Future<void> _onLevelTap(WorldLevel level) async {
    final bool isUnlocked = level.isUnlocked || level.isUnlocked == true;

    if (!isUnlocked) {
      _showSnackBar('Level ${level.orderIndex} is locked!', Colors.orange);
      return;
    }

    final levelController = Get.find<LevelController>();

    // Set ids for the controller
    levelController.worldId = widget.world.id;
    levelController.levelId = level.id;

    // Fetch level detail -> triggers LoadingOverlay on this page
    await levelController.fetchLevelDetail();

    final currentLevel = levelController.currentLevel.value;
    if (currentLevel == null || currentLevel.id != level.id) {
      _showSnackBar('Failed to load level', Colors.red);
      return;
    }

    final route = RouteBuilder.build(AppRoutes.level, {
      'worldId': widget.world.id.toString(),
      'levelId': level.id.toString(),
    });

    Get.toNamed(route);
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / _originalMapWidth;
    final scaledMapHeight = _originalMapHeight * scaleFactor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade100, Colors.green.shade100],
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          width: screenWidth,
          height: scaledMapHeight,
          child: Stack(
            children: [
              _buildMapBackground(scaledMapHeight, screenWidth),
              _buildLevels(scaleFactor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapBackground(double height, double width) {
    return Image.asset(
      "assets/images/map_background.jpg",
      width: width,
      height: height,
      fit: BoxFit.fitWidth,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.landscape, size: 100, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildLevels(double scaleFactor) {
    final levels = widget.world.levels;

    return Stack(
      children: [
        for (int i = 0; i < levels.length; i++)
          if (i < _levelPositions.length)
            _buildLevelItem(
              levels[i],
              i,
              _levelPositions[i]['x']! * scaleFactor,
              _levelPositions[i]['y']! * scaleFactor,
            ),
      ],
    );
  }

  Widget _buildLevelItem(WorldLevel level, int index, double left, double top) {
    return Positioned(
      left: left,
      top: top,
      child: LevelCircle(level: level, onTap: _onLevelTap),
    );
  }
}

class LevelCircle extends StatelessWidget {
  final WorldLevel level;
  final Function(WorldLevel) onTap;

  const LevelCircle({super.key, required this.level, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isUnlocked = level.isUnlocked == 1 || level.isUnlocked == true;
    final double progress = level.completionPercentage / 100.0;
    final bool isCompleted = progress >= 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => onTap(level),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : Colors.blue,
                  ),
                ),
              ),
              _buildLevelCircle(isUnlocked, level.orderIndex),
              if (isCompleted) _buildCompletionBadge(),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Level title
        _buildLevelTitle(level.name),
      ],
    );
  }

  Widget _buildLevelCircle(bool isUnlocked, int orderIndex) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(
          color: isUnlocked ? Colors.blue : Colors.grey,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: isUnlocked
            ? Text(
                '$orderIndex',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              )
            : const Icon(Icons.lock, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildCompletionBadge() {
    return Positioned(
      right: 2,
      top: 2,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 10),
      ),
    );
  }

  Widget _buildLevelTitle(String name) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
