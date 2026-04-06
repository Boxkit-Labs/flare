import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/core/models/models.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/widgets/status_indicator.dart';
import 'package:flare_app/features/watchers/presentation/widgets/animated_budget_bar.dart';
import 'package:intl/intl.dart';

class WatcherCard extends StatelessWidget {
  final WatcherModel watcher;

  const WatcherCard({super.key, required this.watcher});

  String _getEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'flight':
      case 'flights': return '✈️';
      case 'crypto': return '💰';
      case 'news': return '📰';
      case 'product':
      case 'products': return '🛍️';
      case 'job':
      case 'jobs': return '💼';
      case 'stock':
      case 'stocks': return '📊';
      case 'realestate': return '🏠';
      case 'sports': return '⚽';
      default: return '👻';
    }
  }

  String _getLastCheckText(String? lastCheckAt) {
    if (lastCheckAt == null) return 'Never checked';
    try {
      final date = DateTime.parse(lastCheckAt);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentUsed = watcher.budgetPercentUsed ?? 0.0;
    
    return InkWell(
      onTap: () => context.push('/watchers/${watcher.watcherId}'),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _getEmoji(watcher.type),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                StatusIndicator(status: watcher.status),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              watcher.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Checked ${_getLastCheckText(watcher.lastCheckAt)}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'BUDGET',
                      style: TextStyle(
                        fontSize: 9, 
                        fontWeight: FontWeight.w900, 
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${(percentUsed * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.w900, 
                        color: percentUsed > 0.8 ? AppTheme.error : AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedBudgetBar(
                  percentUsed: percentUsed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

