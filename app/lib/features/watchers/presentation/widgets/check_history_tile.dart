import 'package:flutter/material.dart';
import 'package:flare_app/core/models/models.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class CheckHistoryTile extends StatelessWidget {
  final CheckModel check;

  const CheckHistoryTile({super.key, required this.check});

  String _formatValueSummary(Map<String, dynamic>? responseData) {
    if (responseData == null) return 'No data';
    // Simplified summary logic based on service/type
    if (responseData.containsKey('price')) return 'Price: \$${responseData['price']}';
    if (responseData.containsKey('count')) return 'Count: ${responseData['count']}';
    if (responseData.containsKey('items')) return 'Items: ${(responseData['items'] as List).length}';
    return 'Check complete';
  }

  Future<void> _launchStellar(String hash) async {
    final url = Uri.parse('https://stellar.expert/explorer/testnet/tx/$hash');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(check.checkedAt);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('MMM d, HH:mm').format(date),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(
               color: AppTheme.surface,
               borderRadius: BorderRadius.circular(4),
             ),
             child: Text(
              '\$${check.costUsdc.toStringAsFixed(3)}',
              style: const TextStyle(fontSize: 10, color: AppTheme.secondary),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _formatValueSummary(check.responseData),
                style: const TextStyle(fontSize: 13),
              ),
              if (check.findingDetected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.star, color: Colors.orange, size: 14),
              ],
            ],
          ),
          if (check.agentReasoning != null) ...[
            const SizedBox(height: 4),
            Text(
              check.agentReasoning!,
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
      trailing: check.stellarTxHash != null 
          ? IconButton(
              icon: const Icon(Icons.link, size: 16, color: AppTheme.primary),
              onPressed: () => _launchStellar(check.stellarTxHash!),
            )
          : null,
    );
  }
}
