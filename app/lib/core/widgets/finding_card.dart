import 'package:flutter/material.dart';
import 'package:ghost_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class FindingCard extends StatelessWidget {
  final String type;
  final String watcherId;
  final String watcherName;
  final String headline;
  final String detailPreview;
  final DateTime timestamp;
  final double cost;
  final bool isUnread;
  final VoidCallback onTap;

  const FindingCard({
    super.key,
    required this.type,
    required this.watcherId,
    required this.watcherName,
    required this.headline,
    required this.detailPreview,
    required this.timestamp,
    required this.cost,
    this.isUnread = false,
    required this.onTap,
  });

  Color _getTypeColor() {
    switch (type.toLowerCase()) {
      case 'flights': return Colors.blueAccent;
      case 'crypto': return Colors.orangeAccent;
      case 'news': return Colors.purpleAccent;
      case 'products': return Colors.greenAccent;
      case 'jobs': return Colors.redAccent;
      default: return AppTheme.primary;
    }
  }

  String _getTypeEmoji() {
    switch (type.toLowerCase()) {
      case 'flights': return '✈️';
      case 'crypto': return '💰';
      case 'news': return '📰';
      case 'products': return '📦';
      case 'jobs': return '💼';
      default: return '⚡';
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: typeColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_getTypeEmoji(), style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  watcherName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: typeColor.withValues(alpha: 0.8),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat.jm().format(timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withAlpha(100),
                  ),
                ),
                if (isUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              headline,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detailPreview,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withAlpha(150),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Cost: \$${cost.toStringAsFixed(3)}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
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
