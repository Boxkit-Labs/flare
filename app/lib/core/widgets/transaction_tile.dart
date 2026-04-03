import 'package:flutter/material.dart';
import 'package:ghost_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class TransactionTile extends StatelessWidget {
  final String watcherName;
  final String type;
  final String serviceName;
  final double amount;
  final DateTime timestamp;
  final bool hasFinding;
  final VoidCallback onTap;

  const TransactionTile({
    super.key,
    required this.watcherName,
    required this.type,
    required this.serviceName,
    required this.amount,
    required this.timestamp,
    this.hasFinding = false,
    required this.onTap,
  });

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
    final timeStr = DateFormat.MMMd().add_jm().format(timestamp);
    
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(20), width: 1),
        ),
        child: Center(
          child: Text(
            _getTypeEmoji(),
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              watcherName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasFinding) ...[
            const SizedBox(width: 4),
            const Icon(Icons.star, color: Colors.amberAccent, size: 14),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          '$serviceName • $timeStr',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '-\$${amount.toStringAsFixed(3)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Stellar USDC',
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
