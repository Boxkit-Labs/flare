import 'package:flutter/material.dart';
import 'package:flare_app/core/theme/app_theme.dart';

class StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;
  final bool compact;

  const StatPill({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppTheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: themeColor.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeColor.withAlpha(50),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 12 : 14,
              color: themeColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            compact ? value : '$label: $value',
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: themeColor,
            ),
          ),
        ],
      ),
    );
  }
}
