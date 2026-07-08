import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/presentation/screens/ai_writing/ai_writing_practice_page.dart';
import 'package:mobilepenpal/presentation/widgets/home/randomly_floating_asset.dart';

enum _WritingCategory {
  consonants,
  dependentVowels,
  independentVowels,
  numbers,
}

class AiWritingPage extends StatefulWidget {
  const AiWritingPage({super.key});

  @override
  State<AiWritingPage> createState() => _AiWritingPageState();
}

class _AiWritingPageState extends State<AiWritingPage>
    with SingleTickerProviderStateMixin {
  /// All Khmer character lists.
  static const List<String> _consonants = [
    'ក',
    'ខ',
    'គ',
    'ឃ',
    'ង',
    'ច',
    'ឆ',
    'ជ',
    'ឈ',
    'ញ',
    'ដ',
    'ឋ',
    'ឌ',
    'ឍ',
    'ណ',
    'ត',
    'ថ',
    'ទ',
    'ធ',
    'ន',
    'ប',
    'ផ',
    'ព',
    'ភ',
    'ម',
    'យ',
    'រ',
    'ល',
    'វ',
    'ស',
    'ហ',
    'ឡ',
    'អ',
  ];

  static const List<String> _independentVowels = [
    'ឥ',
    'ឦ',
    'ឧ',
    'ឩ',
    'ឪ',
    'ឫ',
    'ឬ',
    'ឭ',
    'ឮ',
    'ឯ',
    'ឰ',
    'ឱ',
    'ឳ',
  ];

  static const List<String> _dependentVowels = [
    'ា',
    'ិ',
    'ី',
    'ឹ',
    'ឺ',
    'ុ',
    'ូ',
    'ួ',
    'ើ',
    'ឿ',
    'ៀ',
    'េ',
    'ែ',
    'ៃ',
    'ោ',
    'ៅ',
    'ុំ',
    'ំ',
    'ាំ',
    'ះ',
    'ិះ',
    'ុះ',
    'េះ',
    'ោះ',
  ];

  static const List<String> _numbers = [
    '០',
    '១',
    '២',
    '៣',
    '៤',
    '៥',
    '៦',
    '៧',
    '៨',
    '៩',
  ];

  /// Currently selected category.
  _WritingCategory _currentCategory = _WritingCategory.consonants;

  /// Selected characters across all categories.
  final Set<String> _selected = {};

  /// Repetition count for drawing practice.
  int _repeatCount = 3;

  @override
  void initState() {
    super.initState();
  }

  List<String> _getCurrentList() {
    switch (_currentCategory) {
      case _WritingCategory.consonants:
        return _consonants;
      case _WritingCategory.dependentVowels:
        return _dependentVowels;
      case _WritingCategory.independentVowels:
        return _independentVowels;
      case _WritingCategory.numbers:
        return _numbers;
    }
  }

  void _toggle(String ch) {
    setState(() {
      if (_selected.contains(ch)) {
        _selected.remove(ch);
      } else {
        _selected.add(ch);
      }
    });
  }

  void _selectAllCategory() {
    setState(() {
      _selected.addAll(_getCurrentList());
    });
  }

  void _clearAllCategory() {
    setState(() {
      _selected.removeAll(_getCurrentList());
    });
  }

  void _startPractice() {
    if (_selected.isEmpty) return;

    // Sort selected characters to match logical order across all lists.
    final List<String> allOrdered = [
      ..._consonants,
      ..._dependentVowels,
      ..._independentVowels,
      ..._numbers,
    ];
    final ordered = allOrdered.where((c) => _selected.contains(c)).toList();

    Get.to(
      () =>
          AiWritingPracticePage(characters: ordered, repeatCount: _repeatCount),
    );
  }

  Color _getCategoryColor(_WritingCategory cat) {
    switch (cat) {
      case _WritingCategory.consonants:
        return const Color(0xFF009688); // Teal
      case _WritingCategory.dependentVowels:
        return const Color(0xFF845EF7); // Purple
      case _WritingCategory.independentVowels:
        return const Color(0xFFE91E63); // Pink
      case _WritingCategory.numbers:
        return const Color(0xFFFF9F43); // Orange
    }
  }

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();
    final bool isStudent = homeController.currentMode.value == 'student';
    final activeThemeColor = _getCategoryColor(_currentCategory);

    return Scaffold(
      body: Stack(
        children: [
          // ── Beautiful Sky/Cartoon Background ───────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/backgrounds/ai_writing_background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // ── Drifting Cartoon Decors (Student Mode) ──────────────────
          if (isStudent) ...[
            const RandomlyFloatingAsset(
              assetPath: 'assets/images/illustrations/balloon.png',
              width: 90,
              minTop: 80,
              maxTop: 450,
              minLeft: -30,
              maxLeft: 260,
            ),
            const RandomlyFloatingAsset(
              assetPath: 'assets/images/decorations/cute_star_decor.png',
              width: 48,
              minTop: 120,
              maxTop: 550,
              minRight: -20,
              maxRight: 240,
            ),
            const RandomlyFloatingAsset(
              assetPath: 'assets/images/illustrations/bird.png',
              width: 65,
              minTop: 220,
              maxTop: 650,
              minLeft: -30,
              maxLeft: 260,
            ),
          ],

          // ── Scrollable content body ────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top header bar ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _BouncyGestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1E293B),
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFF1E293B),
                                offset: Offset(0, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF1E293B),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'my_writing'.tr,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isStudent
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                        ),
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Horizontal category tabs ──────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        _CategoryTabRedesign(
                          label: 'consonants'.tr,
                          icon: Icons.abc_rounded,
                          isSelected:
                              _currentCategory == _WritingCategory.consonants,
                          themeColor: _getCategoryColor(
                            _WritingCategory.consonants,
                          ),
                          onTap: () => setState(
                            () =>
                                _currentCategory = _WritingCategory.consonants,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _CategoryTabRedesign(
                          label: 'dependent_vowels'.tr,
                          icon: Icons.font_download_outlined,
                          isSelected:
                              _currentCategory ==
                              _WritingCategory.dependentVowels,
                          themeColor: _getCategoryColor(
                            _WritingCategory.dependentVowels,
                          ),
                          onTap: () => setState(
                            () => _currentCategory =
                                _WritingCategory.dependentVowels,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _CategoryTabRedesign(
                          label: 'independent_vowels'.tr,
                          icon: Icons.text_format_rounded,
                          isSelected:
                              _currentCategory ==
                              _WritingCategory.independentVowels,
                          themeColor: _getCategoryColor(
                            _WritingCategory.independentVowels,
                          ),
                          onTap: () => setState(
                            () => _currentCategory =
                                _WritingCategory.independentVowels,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _CategoryTabRedesign(
                          label: 'numbers'.tr,
                          icon: Icons.numbers_rounded,
                          isSelected:
                              _currentCategory == _WritingCategory.numbers,
                          themeColor: _getCategoryColor(
                            _WritingCategory.numbers,
                          ),
                          onTap: () => setState(
                            () => _currentCategory = _WritingCategory.numbers,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Character sticker grid board ──────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 12),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 82,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                      itemCount: _getCurrentList().length,
                      itemBuilder: (context, i) {
                        final ch = _getCurrentList()[i];
                        final isSel = _selected.contains(ch);
                        return _CharBlockTile(
                          character: ch,
                          isSelected: isSel,
                          activeColor: activeThemeColor,
                          onTap: () => _toggle(ch),
                        );
                      },
                    ),
                  ),
                ),

                // ── Bottom play control board dock ─────────────────────────
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF5), // Light warm vanilla board
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFF1E293B),
                      width: 3.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF1E293B),
                        offset: Offset(0, 8),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Select All / Clear Row + Practice Times
                      Row(
                        children: [
                          // Select All Button
                          _BouncyGestureDetector(
                            onTap: _selectAllCategory,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF1E293B),
                                  width: 2.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF1E293B),
                                    offset: Offset(0, 3),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.select_all_rounded,
                                    size: 16,
                                    color: activeThemeColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'select_all'.tr,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Clear Button
                          _BouncyGestureDetector(
                            onTap: _clearAllCategory,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF1E293B),
                                  width: 2.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF1E293B),
                                    offset: Offset(0, 3),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.deselect_rounded,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'clear'.tr,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          ...[1, 2, 3, 5].map((count) {
                            final isSel = _repeatCount == count;
                            return Padding(
                              padding: const EdgeInsets.only(left: 3),
                              child: _BouncyGestureDetector(
                                onTap: () =>
                                    setState(() => _repeatCount = count),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? activeThemeColor
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF1E293B),
                                      width: 2.2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0xFF1E293B),
                                        offset: Offset(0, 2),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${count}x',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: isSel
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Playful neobrutalist Start Button
                      _BouncyGestureDetector(
                        onTap: _startPractice,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _selected.isNotEmpty
                                ? const Color(0xFFFF7A00)
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF1E293B),
                              width: 3,
                            ),
                            boxShadow: _selected.isNotEmpty
                                ? const [
                                    BoxShadow(
                                      color: Color(0xFF1E293B),
                                      offset: Offset(0, 5),
                                      blurRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.draw_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selected.isEmpty
                                    ? 'select_characters_tip'.tr
                                    : '${'start_practice'.tr} (${_selected.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Redesigned Helper Widgets
// ═══════════════════════════════════════════════════════════════════════════

class _CategoryTabRedesign extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color themeColor;
  final VoidCallback onTap;

  const _CategoryTabRedesign({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.themeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _BouncyGestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1E293B),
            width: isSelected ? 3.0 : 2.5,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0xFF1E293B),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0xFF1E293B),
                    offset: Offset(0, 2.5),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : themeColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharBlockTile extends StatelessWidget {
  final String character;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _CharBlockTile({
    required this.character,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _BouncyGestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E293B), width: 3),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0xFF1E293B),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0xFF1E293B),
                    offset: Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              character,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            if (isSelected)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BouncyGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _BouncyGestureDetector({required this.child, required this.onTap});

  @override
  State<_BouncyGestureDetector> createState() => _BouncyGestureDetectorState();
}

class _BouncyGestureDetectorState extends State<_BouncyGestureDetector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
