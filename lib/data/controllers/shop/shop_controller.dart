import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/services/shop_service.dart';

class ShopAvatar {
  final String id;
  final String nameEn;
  final String nameKh;
  final int price;
  final String? assetPath;
  final IconData? icon;
  final Color color;

  const ShopAvatar({
    required this.id,
    required this.nameEn,
    required this.nameKh,
    required this.price,
    this.assetPath,
    this.icon,
    this.color = Colors.grey,
  });

  String get name {
    final locale = Get.locale?.languageCode ?? 'en';
    if (locale == 'km') {
      return nameKh;
    }
    return nameEn;
  }
}

class ShopController extends GetxController {
  final GetStorage _box = GetStorage();
  final ShopService _shopService = ShopService();

  static const String _pointsKey = 'adventure_points';
  static const String _unlockedKey = 'unlocked_avatars';
  static const String _selectedKey = 'selected_avatar';

  final totalPoints = 0.obs;
  final unlockedAvatarIds = <String>[].obs;
  final selectedAvatarId = 'default'.obs;

  final allAvatars = <ShopAvatar>[].obs;
  final isPurchasing = false.obs;

  static const List<ShopAvatar> defaultAvatars = [
    ShopAvatar(
      id: 'default',
      nameEn: 'Student',
      nameKh: 'សិស្ស',
      price: 0,
      icon: Icons.person,
      color: Color(0xFF2B7A78),
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _initShop();
  }

  Future<void> _initShop() async {
    await _loadAvatarsFromAssets();
    _loadFromStorage();
    _syncWithStudent();
    _sortAvatars();
  }

  void _syncWithStudent() {
    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();

      if (homeController.student.value != null) {
        totalPoints.value = homeController.student.value!.coin;
        _box.write(_pointsKey, totalPoints.value);
        unlockedAvatarIds.assignAll(
          homeController.student.value!.unlockedAvatars,
        );
        _ensureFreeAvatarsUnlocked();
        _saveUnlocked();
        _sanitizeSelectedAvatar();
        _sortAvatars();
      }

      ever(homeController.student, (Student? s) {
        if (s != null) {
          totalPoints.value = s.coin;
          _box.write(_pointsKey, totalPoints.value);
          unlockedAvatarIds.assignAll(s.unlockedAvatars);
          _ensureFreeAvatarsUnlocked();
          _saveUnlocked();
          _sanitizeSelectedAvatar();
          _sortAvatars();
        }
      });
    }
  }

  Future<void> _loadAvatarsFromAssets() async {
    final List<ShopAvatar> avatars = List.from(defaultAvatars);

    try {
      final List<String> assetPaths = [];
      try {
        final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
          rootBundle,
        );
        assetPaths.addAll(
          manifest
              .listAssets()
              .where((path) => path.contains('assets/images/avatars/'))
              .where(
                (path) =>
                    path.endsWith('.png') ||
                    path.endsWith('.jpg') ||
                    path.endsWith('.jpeg'),
              ),
        );
      } catch (e) {
        final manifestContent = await rootBundle.loadString(
          'AssetManifest.json',
        );
        final Map<String, dynamic> manifestMap = json.decode(manifestContent);
        assetPaths.addAll(
          manifestMap.keys
              .where((key) => key.contains('assets/images/avatars/'))
              .where(
                (key) =>
                    key.endsWith('.png') ||
                    key.endsWith('.jpg') ||
                    key.endsWith('.jpeg'),
              ),
        );
      }

      for (final path in assetPaths) {
        final fileName = path.split('/').last;
        final nameWithoutExt = fileName.split('.').first;

        final parts = nameWithoutExt.split('_');
        String nameEn = '';
        String nameKh = '';
        int price = 50;

        if (parts.length >= 3) {
          final rawEn = parts[0];
          nameEn = rawEn[0].toUpperCase() + rawEn.substring(1).toLowerCase();
          nameKh = parts[1].replaceAll('-', ' ');
          price = int.tryParse(parts[2]) ?? 50;
        } else if (parts.length == 2) {
          final rawEn = parts[0];
          nameEn = rawEn[0].toUpperCase() + rawEn.substring(1).toLowerCase();
          nameKh = nameEn;
          price = int.tryParse(parts[1]) ?? 50;
        } else {
          final rawEn = nameWithoutExt;
          nameEn = rawEn[0].toUpperCase() + rawEn.substring(1).toLowerCase();
          nameKh = nameEn;
        }

        avatars.add(
          ShopAvatar(
            id: nameWithoutExt,
            nameEn: nameEn,
            nameKh: nameKh,
            price: price,
            assetPath: path,
            color: _getRandomAvatarColor(nameWithoutExt),
          ),
        );
      }
    } catch (e) {
      debugPrint('ShopController: Critical error loading avatars: $e');
    }

    // Sort avatars by price in ascending order
    avatars.sort((a, b) => a.price.compareTo(b.price));
    allAvatars.assignAll(avatars);
  }

  Color _getRandomAvatarColor(String id) {
    final colors = [
      const Color(0xFFF39C12), // Orange
      const Color(0xFFE74C3C), // Red
      const Color(0xFF6C63FF), // Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFFE84393), // Pink
      const Color(0xFF3F51B5), // Indigo
    ];

    return colors[id.length % colors.length];
  }

  void _loadFromStorage() {
    totalPoints.value = _box.read<int>(_pointsKey) ?? 0;

    final savedUnlocked = _box.read<List<dynamic>>(_unlockedKey);
    if (savedUnlocked != null) {
      unlockedAvatarIds.assignAll(savedUnlocked.cast<String>());
    }

    _ensureFreeAvatarsUnlocked();
    _saveUnlocked();

    selectedAvatarId.value = _box.read<String>(_selectedKey) ?? 'default';
    _sanitizeSelectedAvatar();
  }

  bool isAvatarUnlocked(ShopAvatar avatar) {
    if (avatar.id == 'default' || avatar.price == 0) return true;
    if (unlockedAvatarIds.contains(avatar.id)) return true;

    final baseId = avatar.id.split('_').first;
    for (final id in unlockedAvatarIds) {
      if (id.split('_').first == baseId) {
        return true;
      }
    }

    return false;
  }

  bool isUnlocked(String avatarId) {
    final avatar = allAvatars.firstWhereOrNull((a) => a.id == avatarId);
    if (avatar == null) return false;
    return isAvatarUnlocked(avatar);
  }

  void _sortAvatars() {
    final List<ShopAvatar> sorted = List.from(allAvatars);
    sorted.sort((a, b) {
      final aUnlocked = isAvatarUnlocked(a);
      final bUnlocked = isAvatarUnlocked(b);

      if (aUnlocked && !bUnlocked) {
        return -1;
      } else if (!aUnlocked && bUnlocked) {
        return 1;
      } else {
        return a.price.compareTo(b.price);
      }
    });
    allAvatars.assignAll(sorted);
  }

  bool isSelected(String avatarId) => selectedAvatarId.value == avatarId;

  void addPoints(int points) {
    totalPoints.value += points;
    _box.write(_pointsKey, totalPoints.value);
  }

  static int calculatePoints({
    required int correct,
    required int total,
    required int stars,
  }) {
    int pointsPerCorrect = 10;
    int bonusStar1 = 5;
    int bonusStar2 = 10;
    int bonusStar3 = 20;

    int pts = correct * pointsPerCorrect;
    if (stars >= 3) {
      pts += bonusStar3;
    } else if (stars >= 2) {
      pts += bonusStar2;
    } else if (stars >= 1) {
      pts += bonusStar1;
    }
    return pts;
  }

  Future<bool> purchaseAvatar(String avatarId) async {
    if (isUnlocked(avatarId)) return true;

    final avatar = allAvatars.firstWhereOrNull((a) => a.id == avatarId);
    if (avatar == null) return false;

    if (totalPoints.value < avatar.price) return false;

    isPurchasing.value = true;
    try {
      final response = await _shopService.purchaseAvatar(
        avatarName: avatar.id,
        cost: avatar.price,
      );

      if (response.code != 200) {
        debugPrint(
          'ShopController: Failed to purchase avatar on backend: ${response.message}',
        );
        return false;
      }

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().student.value = response.data;
      }

      totalPoints.value = response.data!.coin;
      _box.write(_pointsKey, totalPoints.value);

      unlockedAvatarIds.assignAll(response.data!.unlockedAvatars);
      _saveUnlocked();
      _sortAvatars();

      return true;
    } catch (e) {
      debugPrint('ShopController: Error during purchase: $e');
      return false;
    } finally {
      isPurchasing.value = false;
    }
  }

  void selectAvatar(String avatarId) {
    if (!isUnlocked(avatarId)) return;
    selectedAvatarId.value = avatarId;
    _box.write(_selectedKey, avatarId);
  }

  ShopAvatar get currentAvatar {
    if (!isUnlocked(selectedAvatarId.value)) {
      return allAvatars.firstWhereOrNull((a) => a.id == 'default') ??
          (allAvatars.isNotEmpty ? allAvatars.first : defaultAvatars.first);
    }

    return allAvatars.firstWhereOrNull((a) => a.id == selectedAvatarId.value) ??
        (allAvatars.isNotEmpty ? allAvatars.first : defaultAvatars.first);
  }

  void _ensureFreeAvatarsUnlocked() {
    for (final avatar in allAvatars) {
      if (avatar.price == 0 && !unlockedAvatarIds.contains(avatar.id)) {
        unlockedAvatarIds.add(avatar.id);
      }
    }
  }

  void _sanitizeSelectedAvatar() {
    final savedSelection = selectedAvatarId.value;
    if (savedSelection.isEmpty || !isUnlocked(savedSelection)) {
      selectedAvatarId.value = 'default';
      _box.write(_selectedKey, selectedAvatarId.value);
      return;
    }

    _box.write(_selectedKey, savedSelection);
  }

  void _saveUnlocked() {
    _box.write(_unlockedKey, unlockedAvatarIds.toList());
  }
}
