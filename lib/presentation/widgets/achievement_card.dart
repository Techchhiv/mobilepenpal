import 'package:flutter/material.dart';

class AchievementCard extends StatelessWidget {
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final double iconSize;
  final String title;
  final String subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderWidth;
  final Widget? trailingIcon;

  const AchievementCard({
    super.key,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = Colors.white,
    this.iconBackgroundColor = Colors.green,
    this.iconSize = 24,
    this.titleStyle,
    this.subtitleStyle,
    this.onTap,
    this.borderRadius = 12,
    this.padding,
    this.margin,
    this.borderWidth = 1.5,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: iconSize,
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: titleStyle ??
                            const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: subtitleStyle ??
                            TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                
                if (trailingIcon != null) trailingIcon!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
