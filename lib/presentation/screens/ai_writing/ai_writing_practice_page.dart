import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilepenpal/data/controllers/ai_writing/ai_writing_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_audio_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/presentation/screens/ai_writing/ai_writing_summary_page.dart';
import 'package:mobilepenpal/presentation/widgets/world/board_grid_painter.dart';
import 'package:mobilepenpal/presentation/widgets/world/letter_painter.dart';
import 'package:mobilepenpal/presentation/widgets/world/stage_components/stage_attempts_indicator.dart';
import 'package:mobilepenpal/presentation/widgets/ai_writing/predictive_strokes_painter.dart';
import 'package:mobilepenpal/presentation/widgets/world/progressive_strokes_painter.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  AI WRITING PRACTICE PAGE – Gamified neobrutalist design for children
// ═══════════════════════════════════════════════════════════════════════════

class AiWritingPracticePage extends StatefulWidget {
  const AiWritingPracticePage({
    super.key,
    required this.characters,
    required this.repeatCount,
  });

  final List<String> characters;
  final int repeatCount;

  @override
  State<AiWritingPracticePage> createState() => _AiWritingPracticePageState();
}

class _AiWritingPracticePageState extends State<AiWritingPracticePage>
    with TickerProviderStateMixin {
  late final AiWritingController _controller;
  late final ConfettiController _confettiCtrl;

  // Star bounce animation when a star fills in
  late final AnimationController _starBounceCtrl;
  late final Animation<double> _starBounceAnim;

  // ── Theme helpers ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));
    _controller = Get.put(
      AiWritingController(
        characters: widget.characters,
        repeatCount: widget.repeatCount,
      ),
    );

    _starBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _starBounceAnim = Tween<double>(begin: 1.0, end: 1.35)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_starBounceCtrl);
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _starBounceCtrl.dispose();
    Get.delete<AiWritingController>();
    super.dispose();
  }



  void _showPauseDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFBF3), Color(0xFFFFF4E1)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 26,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.orange.shade200,
                          Colors.orange.shade500,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.pause_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Container(
                    width: 56,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade200.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      // Home Button
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                              side: BorderSide(
                                color: Colors.blue.shade100,
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            Get.back(); // Leave practice page and go back to character selection
                          },
                          child: const Icon(Icons.home_rounded, size: 34),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Reset/Retry Button
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.orange.shade500,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                              side: BorderSide(
                                color: Colors.orange.shade200,
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _controller.clearBoard();
                            _controller.attemptLeft.value = 3;
                            _controller.restartGuideFromStart();
                          },
                          child: const Icon(Icons.refresh_rounded, size: 34),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Resume Button
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.green.shade500,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                          },
                          child: const Icon(Icons.play_arrow_rounded, size: 34),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Play character pronunciation ───────────────────────────────────────
  void _playCharacterSound() {
    final audio = Get.isRegistered<StageAudioController>()
        ? Get.find<StageAudioController>()
        : Get.put(StageAudioController());

    final modelType = _controller.getModelTypeForChar(_controller.currentChar);
    audio.playCharacter(type: modelType, ch: _controller.currentChar);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        _showPauseDialog(context);
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/backgrounds/ai_writing_practice_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // ── Floating decorative background assets ──
                ..._buildFloatingAssets(),

                // ── Main content ──
                Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildGameHud(),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildMainArea(),
                      ),
                    ),
                    _buildAiPredictionControls(),
                    const SizedBox(height: 8),
                    _buildBottomActionBar(),
                    const SizedBox(height: 16),
                  ],
                ),

                // ── Confetti overlay ──
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiCtrl,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    numberOfParticles: 30,
                    gravity: 0.15,
                    emissionFrequency: 0.06,
                    colors: const [
                      Color(0xFF2EC4B6),
                      Color(0xFFF59E0B),
                      Color(0xFFEF4444),
                      Color(0xFF8B5CF6),
                      Color(0xFF10B981),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  FLOATING DECORATIVE ASSETS (subtle animated shapes)
  // ─────────────────────────────────────────────────────────────────────────
  List<Widget> _buildFloatingAssets() {
    return [
      // Top-left soft circle
      Positioned(
        top: -30,
        left: -20,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFC107).withValues(alpha: 0.12),
          ),
        ),
      ),
      // Bottom-right soft circle
      Positioned(
        bottom: -40,
        right: -30,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4CAF50).withValues(alpha: 0.10),
          ),
        ),
      ),
      // Middle-right small star emoji
      Positioned(
        top: 140,
        right: 12,
        child: Text(
          '⭐',
          style: TextStyle(
            fontSize: 18,
            color: Colors.amber.withValues(alpha: 0.5),
          ),
        ),
      ),
      // Bottom-left pencil emoji
      Positioned(
        bottom: 100,
        left: 12,
        child: Text(
          '✏️',
          style: TextStyle(
            fontSize: 16,
            color: Colors.orange.withValues(alpha: 0.4),
          ),
        ),
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  GAME HUD HEADER (close btn ▸ star track ▸ avatar)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildGameHud() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1E293B),
            width: 2.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF1E293B),
              offset: Offset(3, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ─ Avatar on the left ─
            _buildHudAvatar(),
            const SizedBox(width: 12),

            // ─ Star progression track ─
            Expanded(child: _buildStarTrack()),

            const SizedBox(width: 12),

            // ─ Pause button on the right ─
            _buildNeoCircleButton(
              icon: Icons.pause_rounded,
              color: const Color(0xFFFF9800),
              onTap: () => _showPauseDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeoCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF1E293B), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF1E293B),
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildStarTrack() {
    return Obx(() {
      final currentRep = _controller.rep.value;
      final totalReps = widget.repeatCount;
      final results = _controller.repResults;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalReps, (i) {
          final state = i < results.length ? results[i] : null;
          final isCurrent = i == currentRep;

          final Color starColor;
          final IconData starIcon;

          if (state == true) {
            starColor = const Color(0xFFFFC107);
            starIcon = Icons.star_rounded;
          } else if (state == false) {
            starColor = const Color(0xFFEF4444);
            starIcon = Icons.star_rounded;
          } else {
            starColor = Colors.grey.shade300;
            starIcon = Icons.star_border_rounded;
          }

          Widget star = AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              starIcon,
              color: starColor,
              size: isCurrent ? 30 : 26,
            ),
          );

          // Add bounce for the most recently filled star
          if (state != null && i == currentRep - 1) {
            star = AnimatedBuilder(
              animation: _starBounceAnim,
              builder: (_, child) => Transform.scale(
                scale: _starBounceAnim.value,
                child: child,
              ),
              child: star,
            );
          }

          return star;
        }),
      );
    });
  }

  Widget _buildHudAvatar() {
    final homeController = Get.find<HomeController>();
    return Obx(() {
      final ShopAvatar? shopAvatar = homeController.currentShopAvatar;
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFF1E293B),
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF1E293B),
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: shopAvatar != null &&
                  shopAvatar.id != 'default' &&
                  shopAvatar.assetPath != null
              ? Image.asset(shopAvatar.assetPath!, fit: BoxFit.cover)
              : const Icon(Icons.person, size: 24, color: Colors.grey),
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  MAIN AREA (guide board + writing slate)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMainArea() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return Column(
        children: [
          // ── Reference Guide Card ──
          _buildGuideCard(),
          const SizedBox(height: 12),
          // ── Writing Slate Canvas ──
          Expanded(child: _buildWritingSlate()),
        ],
      );
    });
  }

  String? _getCharacterImagePath(String char) {
    const consonantImages = {
      'ក': 'assets/images/consonants/ក_កុក.png',
      'ខ': 'assets/images/consonants/ខ_ខ្លា.png',
      'គ': 'assets/images/consonants/គ_គោ.png',
      'ឃ': 'assets/images/consonants/ឃ_ឃ្មុំ.png',
      'ង': 'assets/images/consonants/ង_ងាវ.png',
      'ច': 'assets/images/consonants/ច_ចាប.png',
      'ឆ': 'assets/images/consonants/ឆ_ឆ្មា.png',
      'ជ': 'assets/images/consonants/ជ_ជ្រុក.png',
      'ឈ': 'assets/images/consonants/ឈ_ឈ្លូស.png',
      'ញ': 'assets/images/consonants/ញ_ញញួរ.png',
      'ដ': 'assets/images/consonants/ដ_ដំរី.png',
      'ឋ': 'assets/images/consonants/ឋ_សាលា.png',
      'ឌ': 'assets/images/consonants/ឌ_ដង្កូវ.png',
      'ឍ': 'assets/images/consonants/ឍ_ឍាមរ៉ា.png',
      'ណ': 'assets/images/consonants/ណ_កណ្ដឹង.png',
      'ត': 'assets/images/consonants/ត_ត្រី.png',
      'ថ': 'assets/images/consonants/ថ_ថូ.png',
      'ទ': 'assets/images/consonants/ទ_ទា.png',
      'ធ': 'assets/images/consonants/ធ_ធុង.png',
      'ន': 'assets/images/consonants/ន_នាគ.png',
      'ប': 'assets/images/consonants/ប_បាល់.png',
      'ផ': 'assets/images/consonants/ផ_ផ្កា.png',
      'ព': 'assets/images/consonants/ព_ពពែ.png',
      'ភ': 'assets/images/consonants/ភ_ភេ.png',
      'ម': 'assets/images/consonants/ម_មាន់.png',
      'យ': 'assets/images/consonants/យ_យក្ស.png',
      'រ': 'assets/images/consonants/រ_រុយ.png',
      'ល': 'assets/images/consonants/ល_លា.png',
      'វ': 'assets/images/consonants/វ_វែនតា.png',
      'ស': 'assets/images/consonants/ស_ស្វា.png',
      'ហ': 'assets/images/consonants/ហ_យន្តហោះ.png',
      'ឡ': 'assets/images/consonants/ឡ_ឡាន.png',
      'អ': 'assets/images/consonants/អ_អណ្ដើក.png',

      '០': 'assets/images/fruits/empty_basket.png',
      '១': 'assets/images/fruits/apple.png',
      '២': 'assets/images/fruits/orange.png',
      '៣': 'assets/images/fruits/grape.png',
      '៤': 'assets/images/fruits/banana.png',
      '៥': 'assets/images/fruits/strawberry.png',
      '៦': 'assets/images/fruits/watermelon.png',
      '៧': 'assets/images/fruits/apple.png',
      '៨': 'assets/images/fruits/orange.png',
      '៩': 'assets/images/fruits/banana.png',

      // Dependent Vowels
      'ា': 'assets/images/dep_vowels/ា_កា.png',
      'ាំ': 'assets/images/dep_vowels/ាំ_កាំជណ្ដើរ.png',
      'ិ': 'assets/images/dep_vowels/ិ_ផ្លិត.png',
      'ិះ': 'assets/images/dep_vowels/ិះ_ជិះ.png',
      'ី': 'assets/images/dep_vowels/ី_សី.png',
      'ឹ': 'assets/images/dep_vowels/ឹ_មឹក.png',
      'ឺ': 'assets/images/dep_vowels/ឺ_ឈឺ.png',
      'ុ': 'assets/images/dep_vowels/ុ_តុ.png',
      'ុំ': 'assets/images/dep_vowels/ុំ_រុំកាដូ.png',
      'ុះ': 'assets/images/dep_vowels/ុះ_ពពុះ.png',
      'ូ': 'assets/images/dep_vowels/ូ_ដូង.png',
      'ួ': 'assets/images/dep_vowels/ួ_ភួយ.png',
      'ើ': 'assets/images/dep_vowels/ើ_ដើមឈើ.png',
      'ឿ': 'assets/images/dep_vowels/ឿ_គ្រឿង.png',
      'ៀ': 'assets/images/dep_vowels/ៀ_សៀវភៅ.png',
      'េ': 'assets/images/dep_vowels/េ_សេក.png',
      'េះ': 'assets/images/dep_vowels/េះ_ឆេះ.png',
      'ែ': 'assets/images/dep_vowels/ែ_ខ្លែង.png',
      'ៃ': 'assets/images/dep_vowels/ៃ_ស្ពៃ.png',
      'ោ': 'assets/images/dep_vowels/ោ_ខោ.png',
      'ោះ': 'assets/images/dep_vowels/ោះ_កោះ.png',
      'ៅ': 'assets/images/dep_vowels/ៅ_ពូថៅ.png',
      'ំ': 'assets/images/dep_vowels/ំ_នំ.png',
      'ះ': 'assets/images/dep_vowels/ះ_ផ្ទះ.png',

      // Independent Vowels
      'ឥ': 'assets/images/indep_vowels/ឥ_ឥដ្ឋ.png',
      'ឦ': 'assets/images/indep_vowels/ឦ_ឦសាន.png',
      'ឪ': 'assets/images/indep_vowels/ឪ_ឪឡឹក.png',
      'ឫ': 'assets/images/indep_vowels/ឫ_ឫស.png',
      'ឬ': 'assets/images/indep_vowels/ឬ_ឬស្សី.png',
      'ឭ': 'assets/images/indep_vowels/ឭ_រំឭក.png',
      'ឮ': 'assets/images/indep_vowels/ឮ_ឮ.png',
      'ឰ': 'assets/images/indep_vowels/ឰ_ឰសូរ.png',
      'ឱ': 'assets/images/indep_vowels/ឱ_ឱប.png',
    };
    return consonantImages[char.trim()];
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  REFERENCE GUIDE CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildGuideCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7), // pale yellow
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1E293B),
          width: 2.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF1E293B),
            offset: Offset(3, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Mini guide box with animated strokes (exactly 100x100 to fit glyph space) ──
          Container(
            width: 100,
            height: 100,
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
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                children: [
                  // Grid background
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: BoardGridPainter()),
                    ),
                  ),
                  // Progressive stroke fill overlay
                  Obx(() {
                    final strokes = _controller.guideStrokesPx;
                    if (strokes.isEmpty) return const SizedBox.shrink();
                    return Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: ProgressiveStrokesPainter(
                            guideStrokes: strokes.toList(),
                            completedStrokeCount:
                                _controller.completedGuideStrokeCount.value,
                            currentStrokeFraction:
                                _controller.currentGuideStrokeFraction.value,
                          ),
                        ),
                      ),
                    );
                  }),
                  // Letter guide + animated circle
                  Obx(() {
                    final paths = _controller.miniGuidePaths;
                    if (paths.isEmpty) return const SizedBox.shrink();
                    final guideCircle = _controller.guideCirclePx.value;
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: LetterPointsPainter(
                                letterSubpathsNorm: paths,
                                toBoardPx: (o) => o,
                                fillEnabled: true,
                                strokeEnabled: true,
                                fillOpacity: 0.18,
                                strokeOpacity: 0.30,
                                strokeWidth: 3.5,
                              ),
                            ),
                          ),
                        ),
                        if (guideCircle != null)
                          Positioned(
                            left: guideCircle.dx - 6,
                            top: guideCircle.dy - 6,
                            child: IgnorePointer(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFEF4444),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── Big character badge (Image or Text fallback) in the center ──
          Expanded(
            child: Center(
              child: Obx(() {
                final imagePath = _getCharacterImagePath(_controller.currentChar);
                if (imagePath != null) {
                  return Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1E293B),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF1E293B),
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                    ),
                  );
                } else {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1E293B),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF1E293B),
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _controller.currentChar,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                        height: 1.1,
                      ),
                    ),
                  );
                }
              }),
            ),
          ),

          // ── Action buttons column on the right ──
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Speaker / Sound button
              _buildGuideActionButton(
                icon: Icons.volume_up_rounded,
                color: const Color(0xFFFFC107),
                onTap: _playCharacterSound,
              ),
              const SizedBox(height: 8),
              // Replay guide button
              _buildGuideActionButton(
                icon: Icons.replay_rounded,
                color: const Color(0xFF2EC4B6),
                onTap: _controller.restartGuideFromStart,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E293B), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF1E293B),
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  WRITING SLATE (neobrutalist blackboard canvas)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWritingSlate() {
    return Obx(() {
      final feedback = _controller.feedbackState.value;
      final shakeOffset = _controller.shakeOffset.value;

      double scaleVal = 1.0;
      if (feedback == DrawFeedback.correct) {
        scaleVal = 1.04;
      } else if (feedback == DrawFeedback.wrong) {
        scaleVal = 1.03;
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;

          if ((_controller.canvasSize - size).abs() > 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _controller.canvasSize = size;
            });
          }

          return Center(
            child: AnimatedScale(
              scale: scaleVal,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Transform.translate(
                offset: Offset(
                  feedback == DrawFeedback.wrong ? shakeOffset : 0,
                  0,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFF1E293B),
                          width: 3,
                        ),
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0xFF1E293B),
                            offset: Offset(4, 5),
                          ),
                          BoxShadow(
                            color: feedback == DrawFeedback.correct
                                ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                                : feedback == DrawFeedback.wrong
                                    ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                                    : Colors.transparent,
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: Stack(
                          children: [
                            // Grid pattern
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: BoardGridPainter(),
                                ),
                              ),
                            ),

                            // Drawing board
                            Positioned.fill(
                              child: Obx(() => AbsorbPointer(
                                    absorbing: _controller.isSubmitting.value ||
                                        _controller.feedbackState.value !=
                                            DrawFeedback.none,
                                    child: Listener(
                                      behavior: HitTestBehavior.opaque,
                                      onPointerDown: _controller.onPointerDown,
                                      onPointerMove: _controller.onPointerMove,
                                      onPointerUp: _controller.onPointerUp,
                                      child: DrawingBoard(
                                        boardPanEnabled: false,
                                        boardScaleEnabled: false,
                                        controller:
                                            _controller.drawingController,
                                        background: SizedBox(
                                          width: size,
                                          height: size,
                                        ),
                                      ),
                                    ),
                                  )),
                            ),

                            // Predictive next-stroke prediction overlay
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Obx(() => CustomPaint(
                                      painter: PredictiveStrokesPainter(
                                        predictedSegments:
                                            _controller.autoPredict.value
                                                ? _controller.predictedSegments.toList()
                                                : const [],
                                      ),
                                    )),
                              ),
                            ),

                            // Feedback overlay
                            _buildFeedbackOverlay(),
                          ],
                        ),
                      ),
                    ),

                    // Hearts indicator floating above the board on the top-right
                    Positioned(
                      top: -34,
                      right: 8,
                      child: IgnorePointer(
                        child: Obx(() => StageAttemptsIndicator(
                              attemptLeft: _controller.attemptLeft.value,
                              maxAttempts: 3,
                            )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildFeedbackOverlay() {
    return Obx(() {
      final f = _controller.feedbackState.value;
      final txt = _controller.praiseText.value;
      if (f == DrawFeedback.none || txt.isEmpty) {
        return const SizedBox.shrink();
      }

      final isCorrect = f == DrawFeedback.correct;

      return Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            color: isCorrect
                ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                : const Color(0xFFEF4444).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Lottie.asset(
                    isCorrect
                        ? 'assets/animated/star.json'
                        : 'assets/animated/star_red.json',
                    repeat: false,
                    animate: true,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF1E293B),
                      width: 2.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF1E293B),
                        offset: Offset(2, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    txt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BOTTOM ACTION BAR (Clear + Submit/Next)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // ─── Clear Button (Red) ───
          _Neo3DButton(
            label: 'clear'.tr,
            icon: Icons.delete_outline_rounded,
            bgColor: const Color(0xFFEF4444),
            borderColor: const Color(0xFF1E293B),
            textColor: Colors.white,
            onTap: _controller.clearBoard,
            flex: 1,
          ),
          const SizedBox(width: 12),
          // ─── Submit / Next Button (Green) ───
          Obx(() {
            final isLast =
                _controller.charIndex.value == widget.characters.length - 1 &&
                    _controller.rep.value == widget.repeatCount - 1;
            final isLoading = _controller.isSubmitting.value;

            return _Neo3DButton(
              label: isLast ? 'finish'.tr : 'next'.tr,
              icon: isLast
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
              bgColor: const Color(0xFF4CAF50),
              borderColor: const Color(0xFF1E293B),
              textColor: Colors.white,
              isLoading: isLoading,
              onTap: isLoading
                  ? () {}
                  : () {
                      _controller.checkDrawingAndSubmit(() {
                        Get.to(() => const AiWritingSummaryPage());
                      });
                    },
              flex: 2,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAiPredictionControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // ─── Hint Button ───
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFFFFC107), // Yellow/Amber
              foregroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF1E293B), width: 2.2),
              ),
              shadowColor: const Color(0xFF1E293B),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              _controller.showHint();
            },
            icon: const Icon(
              Icons.lightbulb_rounded,
              size: 20,
            ),
            label: Text(
              'hint'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Neobrutalist 3D Button Widget
// ═══════════════════════════════════════════════════════════════════════════
class _Neo3DButton extends StatefulWidget {
  const _Neo3DButton({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
    this.isLoading = false,
    this.flex = 1,
  });

  final String label;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;
  final bool isLoading;
  final int flex;

  @override
  State<_Neo3DButton> createState() => _Neo3DButtonState();
}

class _Neo3DButtonState extends State<_Neo3DButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: widget.flex,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          transform: Matrix4.translationValues(
            _pressed ? 2 : 0,
            _pressed ? 3 : 0,
            0,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.borderColor,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.borderColor,
                offset: Offset(_pressed ? 1 : 3, _pressed ? 1 : 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.isLoading
                ? [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ]
                : [
                    Icon(widget.icon, color: widget.textColor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: widget.textColor,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
