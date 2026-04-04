import 'package:flutter/material.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/widgets/budget_bar.dart';

class WatcherCard extends StatelessWidget {
  final String type;
  final String name;
  final bool isActive;
  final String latestData;
  final double spent;
  final double limit;
  final VoidCallback onTap;

  const WatcherCard({
    super.key,
    required this.type,
    required this.name,
    required this.isActive,
    required this.latestData,
    required this.spent,
    required this.limit,
    required this.onTap,
  });

  Color _getTypeColor() {
    switch (type.toLowerCase()) {
      case 'flights':
        return Colors.blueAccent;
      case 'crypto':
        return Colors.orangeAccent;
      case 'news':
        return Colors.purpleAccent;
      case 'products':
        return Colors.greenAccent;
      case 'jobs':
        return Colors.redAccent;
      default:
        return AppTheme.primary;
    }
  }

  String _getTypeEmoji() {
    switch (type.toLowerCase()) {
      case 'flights':
        return '✈️';
      case 'crypto':
        return '💰';
      case 'news':
        return '📰';
      case 'products':
        return '📦';
      case 'jobs':
        return '💼';
      default:
        return '👁️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            top: BorderSide(color: typeColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getTypeEmoji(),
                  style: const TextStyle(fontSize: 20),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.greenAccent : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              latestData,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withAlpha(150),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            BudgetBar(
              spent: spent,
              total: limit,
              height: 4,
              showLabel: false,
            ),
            const SizedBox(height: 4),
            Text(
              '\$${spent.toStringAsFixed(2)} / \$${limit.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: typeColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
