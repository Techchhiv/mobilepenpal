import 'package:flutter/material.dart';

class PremiumCourseCard extends StatelessWidget {
  final String courseTitle;
  final String courseSubtitle;
  final String badgeText;
  final int completedLessons;
  final int totalLessons;
  final String buttonText;
  final VoidCallback? onTap;

  const PremiumCourseCard({
    super.key,
    this.courseTitle = '',
    this.courseSubtitle = '',
    this.badgeText = '',
    this.completedLessons = 0,
    this.totalLessons = 1,
    this.buttonText = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(28),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _IconBadge(),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          courseTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _PillBadge(text: badgeText),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37), // Golden metallic
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1E293B), width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF1E293B),
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("🔒", style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  buttonText,
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
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E293B), width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF1E293B),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: const Center(child: Text("🔒", style: TextStyle(fontSize: 24))),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String text;

  const _PillBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF1E293B), width: 2),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
