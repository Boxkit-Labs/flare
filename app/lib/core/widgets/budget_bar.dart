import 'package:flutter/material.dart';
import 'package:ghost_app/core/theme/app_theme.dart';

class BudgetBar extends StatelessWidget {
  final double spent;
  final double total;
  final double height;
  final bool showLabel;

  const BudgetBar({
    super.key,
    required this.spent,
    required this.total,
    this.height = 8.0,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = (total > 0) ? (spent / total).clamp(0.0, 1.0) : 0.0;
    
    // Choose color based on percentage
    Color progressColor;
    if (percentage < 0.6) {
      progressColor = Colors.greenAccent;
    } else if (percentage < 0.8) {
      progressColor = Colors.orangeAccent;
    } else {
      progressColor = Colors.redAccent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: \$${spent.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
              Text(
                'Limit: \$${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: Colors.white.withAlpha(20), width: 0.5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    progressColor.withAlpha(150),
                    progressColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: [
                  BoxShadow(
                    color: progressColor.withAlpha(80),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
