import 'package:flutter/material.dart';

/// A reusable pause/exit dialog for stage-style screens.
///
/// Passive widget: Caller provides callbacks for actions.
class StagePauseDialog extends StatelessWidget {
  const StagePauseDialog({
    super.key,
    this.title,
    this.description,
    required this.onHome,
    this.onRestart,
    required this.onResume,
    this.icon = Icons.pause_rounded,
    this.iconGradientColors,
  });

  /// The main title of the dialog.
  final String? title;

  /// The description text.
  final String? description;

  /// Called when the home button is pressed.
  final VoidCallback onHome;

  /// Called when the restart button is pressed.
  /// If null, the restart button will be hidden.
  final VoidCallback? onRestart;

  /// Called when the resume button is pressed.
  final VoidCallback onResume;

  /// The main icon at the top of the dialog.
  final IconData icon;

  /// Optional gradient colors for the icon background.
  final List<Color>? iconGradientColors;

  @override
  Widget build(BuildContext context) {
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
              // Top Icon
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: iconGradientColors ??
                        [
                          Colors.orange.shade200,
                          Colors.orange.shade500,
                        ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (iconGradientColors?.last ?? Colors.orange)
                          .withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 56,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 22),

              // Decorative line
              Container(
                width: 56,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.orange.shade200.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              if (title != null) ...[
                const SizedBox(height: 16),
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4A4A4A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              if (description != null) ...[
                const SizedBox(height: 8),
                Text(
                  description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 22),

              Row(
                children: [
                  // Home Button
                  Expanded(
                    child: _buildButton(
                      onPressed: onHome,
                      icon: Icons.home_rounded,
                      bg: Colors.white,
                      fg: Colors.blue.shade600,
                      border: Colors.blue.shade100,
                    ),
                  ),
                  
                  if (onRestart != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildButton(
                        onPressed: onRestart!,
                        icon: Icons.refresh_rounded,
                        bg: Colors.white,
                        fg: Colors.orange.shade500,
                        border: Colors.orange.shade200,
                      ),
                    ),
                  ],

                  const SizedBox(width: 8),

                  // Resume Button
                  Expanded(
                    child: _buildButton(
                      onPressed: onResume,
                      icon: Icons.play_arrow_rounded,
                      bg: Colors.green.shade500,
                      fg: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color bg,
    required Color fg,
    Color? border,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: bg,
        foregroundColor: fg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: border != null
              ? BorderSide(color: border, width: 2)
              : BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: onPressed,
      child: Icon(icon, size: 34),
    );
  }
}
