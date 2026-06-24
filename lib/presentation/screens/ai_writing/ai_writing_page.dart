import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/presentation/screens/ai_writing/ai_writing_practice_page.dart';

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
    'ក', 'ខ', 'គ', 'ឃ', 'ង',
    'ច', 'ឆ', 'ជ', 'ឈ', 'ញ',
    'ដ', 'ឋ', 'ឌ', 'ឍ', 'ណ',
    'ត', 'ថ', 'ទ', 'ធ', 'ន',
    'ប', 'ផ', 'ព', 'ភ', 'ម',
    'យ', 'រ', 'ល', 'វ', 'ស',
    'ហ', 'ឡ', 'អ',
  ];

  static const List<String> _independentVowels = [
    'ឥ', 'ឦ', 'ឧ', 'ឩ', 'ឪ', 'ឫ', 'ឬ', 'ឭ', 'ឮ', 'ឯ', 'ឰ', 'ឱ', 'ឳ',
  ];

  static const List<String> _dependentVowels = [
    'ា', 'ិ', 'ី', 'ឹ', 'ឺ', 'ុ', 'ូ', 'ួ', 'ើ', 'ឿ', 'ៀ', 'េ', 'ែ', 'ៃ', 'ោ', 'ៅ', 'ុំ', 'ំ', 'ាំ', 'ះ', 'ិះ', 'ុះ', 'េះ', 'ោះ',
  ];

  static const List<String> _numbers = [
    '០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩',
  ];

  /// Currently selected category.
  _WritingCategory _currentCategory = _WritingCategory.consonants;

  /// Selected characters across all categories.
  final Set<String> _selected = {};

  /// Repetition count for drawing practice.
  int _repeatCount = 3;

  late final AnimationController _fabAnimCtrl;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScale = CurvedAnimation(parent: _fabAnimCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _fabAnimCtrl.dispose();
    super.dispose();
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
      if (_selected.isNotEmpty) {
        _fabAnimCtrl.forward();
      } else {
        _fabAnimCtrl.reverse();
      }
    });
  }

  void _selectAllCategory() {
    setState(() {
      _selected.addAll(_getCurrentList());
      if (_selected.isNotEmpty) {
        _fabAnimCtrl.forward();
      }
    });
  }

  void _clearAllCategory() {
    setState(() {
      _selected.removeAll(_getCurrentList());
      if (_selected.isNotEmpty) {
        _fabAnimCtrl.forward();
      } else {
        _fabAnimCtrl.reverse();
      }
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
      () => AiWritingPracticePage(
        characters: ordered,
        repeatCount: _repeatCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();
    final bool isStudent = homeController.currentMode.value == 'student';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isStudent
                ? const [
                    Color(0xFFF3FBFF),
                    Color(0xFFF7F8FF),
                    Color(0xFFFFF7F2),
                  ]
                : const [
                    AppColors.primary,
                    Color(0xFF1e8c79),
                    Color(0xFF49aa7c),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: isStudent
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: isStudent
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.15),
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'my_writing'.tr,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isStudent
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                      ),
                    ),
                    const Spacer(),
                    
                    // Unified selection pill badge in header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isStudent
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isStudent
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: isStudent ? AppColors.primary : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'selected_count'.trParams(
                                {'count': _selected.length.toString()}),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isStudent
                                  ? AppColors.primary
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Main split view ─────────────────────────────────────
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left-side category filter rail
                    Container(
                      width: 105,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 6),
                      decoration: BoxDecoration(
                        color: isStudent
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.12),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _CategoryTab(
                              label: 'consonants'.tr,
                              icon: Icons.abc_rounded,
                              isSelected: _currentCategory ==
                                  _WritingCategory.consonants,
                              isStudent: isStudent,
                              onTap: () => setState(() => _currentCategory =
                                  _WritingCategory.consonants),
                            ),
                            const SizedBox(height: 10),
                            _CategoryTab(
                              label: 'dependent_vowels'.tr,
                              icon: Icons.font_download_outlined,
                              isSelected: _currentCategory ==
                                  _WritingCategory.dependentVowels,
                              isStudent: isStudent,
                              onTap: () => setState(() => _currentCategory =
                                  _WritingCategory.dependentVowels),
                            ),
                            const SizedBox(height: 10),
                            _CategoryTab(
                              label: 'independent_vowels'.tr,
                              icon: Icons.text_format_rounded,
                              isSelected: _currentCategory ==
                                  _WritingCategory.independentVowels,
                              isStudent: isStudent,
                              onTap: () => setState(() => _currentCategory =
                                  _WritingCategory.independentVowels),
                            ),
                            const SizedBox(height: 10),
                            _CategoryTab(
                              label: 'numbers'.tr,
                              icon: Icons.numbers_rounded,
                              isSelected: _currentCategory ==
                                  _WritingCategory.numbers,
                              isStudent: isStudent,
                              onTap: () => setState(() => _currentCategory =
                                  _WritingCategory.numbers),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right-side grid and selectors
                    Expanded(
                      child: Column(
                        children: [
                          // Select All / Clear + Quick repetition picker
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Repetition quick picker
                                Text(
                                  'repeat_count_label'.tr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isStudent
                                        ? const Color(0xFF475569)
                                        : Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    ...[1, 2, 3, 5, 10].map((count) {
                                      final isSel = _repeatCount == count;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: InkWell(
                                          onTap: () => setState(
                                              () => _repeatCount = count),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 150),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isSel
                                                  ? (isStudent
                                                      ? AppColors.primary
                                                      : Colors.white)
                                                  : (isStudent
                                                      ? Colors.white
                                                      : Colors.white.withValues(
                                                          alpha: 0.1)),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: isSel
                                                    ? (isStudent
                                                        ? AppColors.primary
                                                        : Colors.white)
                                                    : (isStudent
                                                        ? Colors.grey.shade300
                                                        : Colors.white
                                                            .withValues(
                                                                alpha: 0.15)),
                                              ),
                                            ),
                                            child: Text(
                                              '${count}x',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                                color: isSel
                                                    ? (isStudent
                                                        ? Colors.white
                                                        : AppColors.primary)
                                                    : (isStudent
                                                        ? const Color(
                                                            0xFF475569)
                                                        : Colors.white),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Select all / clear current category
                                Row(
                                  children: [
                                    _ChipButton(
                                      label: 'select_all'.tr,
                                      icon: Icons.select_all_rounded,
                                      isStudent: isStudent,
                                      onTap: _selectAllCategory,
                                    ),
                                    const SizedBox(width: 8),
                                    _ChipButton(
                                      label: 'clear'.tr,
                                      icon: Icons.deselect_rounded,
                                      isStudent: isStudent,
                                      onTap: _clearAllCategory,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Active character grid
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: GridView.builder(
                                padding: const EdgeInsets.only(bottom: 90),
                                physics: const BouncingScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 1,
                                ),
                                itemCount: _getCurrentList().length,
                                itemBuilder: (context, i) {
                                  final ch = _getCurrentList()[i];
                                  final on = _selected.contains(ch);
                                  return _CharTile(
                                    character: ch,
                                    isSelected: on,
                                    isStudent: isStudent,
                                    onTap: () => _toggle(ch),
                                  );
                                },
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
        ),
      ),

      // ── Floating start button ──────────────────────────────────────
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton.extended(
          onPressed: _startPractice,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.draw_rounded, color: Colors.white),
          label: Text(
            '${'start_practice'.tr} (${_selected.length})',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Private helper widgets
// ═══════════════════════════════════════════════════════════════════════════

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isStudent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isStudent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeBg = isStudent ? AppColors.primary : Colors.white;
    final activeFg = isStudent ? Colors.white : AppColors.primary;
    final inactiveBg = Colors.transparent;
    final inactiveFg = isStudent ? const Color(0xFF475569) : Colors.white70;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected && isStudent
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? activeFg : inactiveFg,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected ? activeFg : inactiveFg,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharTile extends StatelessWidget {
  const _CharTile({
    required this.character,
    required this.isSelected,
    required this.isStudent,
    required this.onTap,
  });

  final String character;
  final bool isSelected;
  final bool isStudent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Border? border;

    if (isSelected) {
      bg = isStudent ? AppColors.primary : Colors.white;
      fg = isStudent ? Colors.white : AppColors.primary;
      border = null;
    } else {
      bg = isStudent
          ? Colors.white.withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.08);
      fg = isStudent ? const Color(0xFF334155) : Colors.white70;
      border = Border.all(
        color: isStudent
            ? Colors.grey.shade200
            : Colors.white.withValues(alpha: 0.12),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: border,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          character,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.label,
    required this.icon,
    required this.isStudent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isStudent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isStudent ? Colors.white : Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16, color: isStudent ? AppColors.primary : Colors.white70),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isStudent ? const Color(0xFF334155) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
