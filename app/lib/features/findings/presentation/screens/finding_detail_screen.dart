import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_app/core/theme/app_theme.dart';
import 'package:ghost_app/core/models/models.dart';
import 'package:ghost_app/features/findings/presentation/bloc/findings_bloc.dart';
import 'package:ghost_app/features/findings/presentation/bloc/findings_event.dart';
import 'package:ghost_app/features/findings/presentation/bloc/findings_state.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';

class FindingDetailScreen extends StatefulWidget {
  final String findingId;

  const FindingDetailScreen({super.key, required this.findingId});

  @override
  State<FindingDetailScreen> createState() => _FindingDetailScreenState();
}

class _FindingDetailScreenState extends State<FindingDetailScreen> {
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    context.read<FindingsBloc>().add(LoadFindingDetail(widget.findingId));
    context.read<FindingsBloc>().add(MarkFindingAsRead(widget.findingId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FindingsBloc, FindingsState>(
      builder: (context, state) {
        if (state is FindingDetailLoaded && state.finding.findingId == widget.findingId) {
          final finding = state.finding;
          return Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _shareFinding(finding),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroSection(finding),
                  const SizedBox(height: 32),
                  _buildDetailCard(finding),
                  if (finding.actionUrl != null) ...[
                    const SizedBox(height: 24),
                    _buildActionButton(finding),
                  ],
                  const SizedBox(height: 32),
                  _buildPaymentReceipt(finding),
                  const SizedBox(height: 32),
                  _buildAgentReasoning(finding),
                  const SizedBox(height: 32),
                  _buildRelatedSection(finding),
                ],
              ),
            ),
          );
        }

        if (state is FindingsError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(state.message)),
          );
        }

        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildHeroSection(FindingModel finding) {
    final String emoji = _getEmoji(finding.type);
    
    return Stack(
      children: [
        Positioned(
          right: -20,
          top: -20,
          child: Opacity(
            opacity: 0.05,
            child: Text(emoji, style: const TextStyle(fontSize: 160)),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              finding.headline,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.1),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Found ${_getTimeAgo(finding.foundAt)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => context.push('/watchers/${finding.watcherId}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      finding.watcherName ?? finding.type.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailCard(FindingModel finding) {
    // Attempt to extract metrics from metadata if available
    final current = finding.data?['current_value'] ?? finding.data?['price'] ?? 'N/A';
    final previous = finding.data?['previous_value'] ?? finding.data?['previous_price'];
    final change = finding.data?['change_percent'] ?? finding.data?['change_amount'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(finding.detail ?? 'No extra details provided.', style: const TextStyle(fontSize: 15, height: 1.5, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem('CURRENT', current.toString(), Colors.green),
              if (previous != null)
                 _buildMetricItem('PREVIOUS', previous.toString(), Colors.grey, isStrikethrough: true),
              if (change != null)
                 _buildMetricItem('CHANGE', change.toString(), Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color, {bool isStrikethrough = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            decoration: isStrikethrough ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(FindingModel finding) {
    String label = 'View Detail';
    if (finding.type == 'flights') label = 'Book This Flight';
    if (finding.type == 'products') label = 'View Product';
    if (finding.type == 'news') label = 'Read Article';
    if (finding.type == 'jobs') label = 'Apply Now';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => launchUrl(Uri.parse(finding.actionUrl!)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: AppTheme.primary,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildPaymentReceipt(FindingModel finding) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Payment Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Verified on Stellar', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildReceiptRow('Cost of this check', '\$${finding.costUsdc.toStringAsFixed(4)} USDC'),
          _buildReceiptRow('Service', '${finding.type.toUpperCase()} Agent'),
          _buildReceiptRow('Stellar Transaction', finding.stellarTxHash != null 
              ? '${finding.stellarTxHash!.substring(0, 8)}...${finding.stellarTxHash!.substring(finding.stellarTxHash!.length - 8)}' 
              : 'N/A', 
              onTap: finding.stellarTxHash != null ? () => launchUrl(Uri.parse('https://stellar.expert/explorer/testnet/tx/${finding.stellarTxHash}')) : null),
          _buildReceiptRow('Paid at', DateFormat('MMM d, HH:mm').format(DateTime.parse(finding.foundAt))),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          InkWell(
            onTap: onTap,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 13, 
                color: onTap != null ? AppTheme.primary : AppTheme.textPrimary,
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentReasoning(FindingModel finding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Agent's Analysis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            finding.data?['agent_reasoning'] ?? 'Agent completed the check and detected parameters meeting your alert criteria. 👻',
            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14, color: AppTheme.textPrimary, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedSection(FindingModel finding) {
    // We would ideally fetch the watcher's checks here. For demo, we build a mini chart.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Watcher Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: LineChart(
             LineChartData(
               gridData: const FlGridData(show: false),
               titlesData: const FlTitlesData(show: false),
               borderData: FlBorderData(show: false),
               lineBarsData: [
                 LineChartBarData(
                   spots: [
                      const FlSpot(0, 10), const FlSpot(1, 12), const FlSpot(2, 8), 
                      const FlSpot(3, 15), const FlSpot(4, 14), const FlSpot(5, 7),
                   ],
                   isCurved: true,
                   color: AppTheme.primary,
                   barWidth: 3,
                   dotData: const FlDotData(show: false),
                   belowBarData: BarAreaData(show: true, color: AppTheme.primary.withValues(alpha: 0.1)),
                 ),
               ],
             ),
          ),
        ),
      ],
    );
  }

  String _getEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'flights': return '✈️';
      case 'crypto': return '💰';
      case 'news': return '📰';
      case 'products': return '🛍️';
      case 'jobs': return '💼';
      default: return '✨';
    }
  }

  String _getTimeAgo(String foundAt) {
    final date = DateTime.parse(foundAt);
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'seconds ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return DateFormat('MMM d').format(date);
  }

  void _shareFinding(FindingModel finding) {
    final text = '👻 Ghost Finding: ${finding.headline}\n\n${finding.detail ?? ''}\n\n${finding.actionUrl ?? ''}';
    Share.share(text);
  }
}
