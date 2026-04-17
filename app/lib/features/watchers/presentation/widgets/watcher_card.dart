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
      case 'events':
      case 'sports': return '🎫';
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
                if (['crypto', 'stock'].contains(watcher.type) && watcher.status == 'active')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                         Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 8),
                         SizedBox(width: 4),
                         Text('LIVE', style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ],
                    ),
                  )
                else
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
            if (watcher.type == 'events' || watcher.type == 'sports')
              _buildEventContent()
            else
              _buildDefaultContent(percentUsed),
          ],
        ),
      ),
    );
  }

  Widget _buildEventContent() {
    final metadata = watcher.parameters ?? {};
    final currentPrice = metadata['current_price'] as String? ?? 'N/A';
    final venue = metadata['venue'] as String? ?? 'Various';
    final isFree = metadata['is_free'] as bool? ?? false;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 10, color: AppTheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  venue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isFree)
            const Text(
              'Free · Availability',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currentPrice, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const Row(
                  children: [
                    Icon(Icons.trending_down, size: 12, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text('Dropped', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultContent(double percentUsed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        AnimatedBudgetBar(percentUsed: percentUsed),
      ],
    );
  }
}

