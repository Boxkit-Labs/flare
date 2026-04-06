import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/core/models/models.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/widgets/status_indicator.dart';
import 'package:flare_app/features/watchers/presentation/widgets/animated_budget_bar.dart';
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
      case 'flight':
        return '✈️';
      case 'crypto':
        return '💰';
      case 'news':
        return '📰';
      case 'products':
      case 'product':
        return '🛍️';
      case 'jobs':
      case 'job':
        return '💼';
      default:
        return '👻';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    watcher.status == 'active' ? Icons.pause_circle_outline : Icons.play_circle_outline,
                    color: AppTheme.primary,
                  ),
                ),
                title: Text(
                  watcher.status == 'active' ? 'Pause Watcher' : 'Resume Watcher',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onToggle(watcher.status != 'active');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_outlined, color: Colors.blue),
                ),
                title: const Text('Edit Configuration', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  if (onEdit != null) onEdit!();
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Divider(),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                title: const Text('Delete Watcher', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  if (onDelete != null) onDelete!();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = watcher.status == 'active';
    final percentUsed = watcher.budgetPercentUsed ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: InkWell(
        onTap: () => context.push('/watchers/${watcher.watcherId}'),
        onLongPress: () => _showOptions(context),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _getEmoji(watcher.type),
                      style: const TextStyle(fontSize: 26),
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
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                             StatusIndicator(status: watcher.status, size: 6),
                             const SizedBox(width: 6),
                             Text(
                              isActive 
                                  ? 'Active · Every ${watcher.checkIntervalMinutes}m'
                                  : watcher.status == 'paused' 
                                      ? 'Paused'
                                      : 'Error',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildToggleSwitch(isActive),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last: ${_getTimeAgo(watcher.lastCheckAt)}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${(percentUsed * 100).toInt()}% budget used',
                    style: TextStyle(
                      fontSize: 11, 
                      color: percentUsed > 0.8 ? Colors.red : AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedBudgetBar(
                percentUsed: percentUsed,
                minHeight: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSwitch(bool isActive) {
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: isActive,
        onChanged: (val) => onToggle(val),
        activeTrackColor: AppTheme.primary.withValues(alpha: 0.2),
        activeColor: AppTheme.primary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

