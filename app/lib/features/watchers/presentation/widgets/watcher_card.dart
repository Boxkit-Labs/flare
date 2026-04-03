import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_app/core/models/models.dart';
import 'package:ghost_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class WatcherCard extends StatelessWidget {
  final WatcherModel watcher;

  const WatcherCard({super.key, required this.watcher});

  String _getEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'flights':
        return '✈️';
      case 'crypto':
        return '💰';
      case 'news':
        return '📰';
      case 'products':
        return '🛍️';
      case 'jobs':
        return '💼';
      default:
        return '👻';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.yellow;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
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
    final budgetColor = percentUsed < 0.5 
        ? Colors.green 
        : (percentUsed < 0.8 ? Colors.yellow : Colors.red);

    return InkWell(
      onTap: () => context.push('/watchers/${watcher.watcherId}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surface.withAlpha(100)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getEmoji(watcher.type),
                  style: const TextStyle(fontSize: 24),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(watcher.status),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              watcher.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getLastCheckText(watcher.lastCheckAt),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
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
                      'Budget',
                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '${(percentUsed * 100).toInt()}%',
                      style: TextStyle(fontSize: 10, color: budgetColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percentUsed.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[850],
                    valueColor: AlwaysStoppedAnimation<Color>(budgetColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
