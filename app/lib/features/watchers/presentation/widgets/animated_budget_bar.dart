import 'package:flutter/material.dart';

class AnimatedBudgetBar extends StatelessWidget {
  final double percentUsed;
  final double minHeight;
  final BorderRadius? borderRadius;

  const AnimatedBudgetBar({
    super.key,
    required this.percentUsed,
    this.minHeight = 4.0,
    this.borderRadius,
  });

  Color _getBudgetColor(double percent) {
    if (percent < 0.5) return Colors.green;
    if (percent < 0.8) return Colors.yellow;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final clampedPercent = percentUsed.clamp(0.0, 1.0);
    final color = _getBudgetColor(clampedPercent);

    return Container(
      height: minHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: borderRadius ?? BorderRadius.circular(minHeight / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * clampedPercent,
                height: minHeight,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: borderRadius ?? BorderRadius.circular(minHeight / 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
