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

  Future<void> _launchStellar(BuildContext context, String hash, bool isOffChain) async {
    if (isOffChain || hash.startsWith('mpp:')) {
        // Show an info dialog for off-chain proof instead of an explorer link
        showDialog(
            context: context, 
            builder: (context) => AlertDialog(
                title: const Text('MPP Session Proof'),
                content: Text('This payment was batched off-chain using the Micro-Payment Protocol.\n\nChannel Signature/ID:\n$hash'),
                actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
                ]
            )
        );
        return;
    }
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                 decoration: BoxDecoration(
                   color: check.isOffChain ? Colors.purple.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(4),
                 ),
                 child: Row(
                   children: [
                     Icon(
                         check.isOffChain ? Icons.bolt_rounded : Icons.language_rounded, 
                         size: 10, 
                         color: check.isOffChain ? Colors.purple : Colors.blue
                     ),
                     const SizedBox(width: 4),
                     Text(
                      check.isOffChain ? 'Off-chain' : 'On-chain',
                      style: TextStyle(
                          fontSize: 8, 
                          fontWeight: FontWeight.bold, 
                          color: check.isOffChain ? Colors.purple : Colors.blue
                      ),
                    ),
                   ],
                 ),
              ),
              const SizedBox(width: 8),
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
              icon: Icon(check.isOffChain ? Icons.receipt_long_rounded : Icons.link, size: 16, color: check.isOffChain ? Colors.purple : AppTheme.primary),
              onPressed: () => _launchStellar(context, check.stellarTxHash!, check.isOffChain),
            )
          : null,
    );
  }
}
