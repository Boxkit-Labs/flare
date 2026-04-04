import 'package:flutter/material.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class BriefingCard extends StatelessWidget {
  final DateTime date;
  final int findingsCount;
  final double totalCost;
  final String summary;
  final bool isLatest;
  final VoidCallback onTap;

  const BriefingCard({
    super.key,
    required this.date,
    required this.findingsCount,
    required this.totalCost,
    required this.summary,
    this.isLatest = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayStr = DateFormat('EEEE').format(date);
    final dateStr = DateFormat('MMMM d').format(date);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: isLatest ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayStr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (isLatest)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LATEST',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStat(Icons.bolt, '$findingsCount Findings', Colors.amberAccent),
                  const SizedBox(width: 16),
                  _buildStat(Icons.account_balance_wallet, '\$${totalCost.toStringAsFixed(2)}', Colors.greenAccent),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summary,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withAlpha(180),
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tap to view full report',
                    style: TextStyle(fontSize: 11, color: AppTheme.primary),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 12, color: AppTheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
