import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_app/core/models/models.dart';
import 'package:ghost_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class WatcherListTile extends StatelessWidget {
  final WatcherModel watcher;
  final Function(bool) onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const WatcherListTile({
    super.key,
    required this.watcher,
    required this.onToggle,
    this.onDelete,
    this.onEdit,
  });

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

  String _getTimeAgo(String? lastCheckAt) {
    if (lastCheckAt == null) return 'Never';
    try {
      final date = DateTime.parse(lastCheckAt);
      final diff = DateTime.now().difference(date);
      if (diff.inSeconds < 60) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                watcher.status == 'active' ? Icons.pause_circle_outline : Icons.play_circle_outline,
                color: AppTheme.textPrimary,
              ),
              title: Text(watcher.status == 'active' ? 'Pause Watcher' : 'Resume Watcher'),
              onTap: () {
                Navigator.pop(context);
                onToggle(watcher.status != 'active');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppTheme.textPrimary),
              title: const Text('Edit Configuration'),
              onTap: () {
                Navigator.pop(context);
                if (onEdit != null) onEdit!();
              },
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.orange),
              title: const Text('Delete Watcher', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                if (onDelete != null) onDelete!();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = watcher.status == 'active';
    final percentUsed = watcher.budgetPercentUsed ?? 0.0;
    final budgetColor = percentUsed < 0.5 
        ? Colors.green 
        : (percentUsed < 0.8 ? Colors.yellow : Colors.red);

    return InkWell(
      onTap: () => context.push('/watchers/${watcher.watcherId}'),
      onLongPress: () => _showOptions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _getEmoji(watcher.type),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        watcher.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isActive 
                            ? 'Checking every ${watcher.checkIntervalMinutes}m · Last: ${_getTimeAgo(watcher.lastCheckAt)}'
                            : watcher.status == 'paused' 
                                ? 'Paused — Tap to resume'
                                : 'Error — Tap to retry',
                        style: TextStyle(
                          color: isActive ? AppTheme.textSecondary : _getStatusColor(watcher.status),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(watcher.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        watcher.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(watcher.status),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Switch(
                      value: isActive,
                      onChanged: onToggle,
                      activeTrackColor: Colors.green.withValues(alpha: 0.5),
                      activeThumbColor: Colors.green,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percentUsed.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[850],
                valueColor: AlwaysStoppedAnimation<Color>(budgetColor),
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
