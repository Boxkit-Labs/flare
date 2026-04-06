import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/models/models.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_bloc.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_event.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_state.dart';
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
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              backgroundColor: AppTheme.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () => _shareFinding(finding),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        }

        if (state is FindingsError) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(backgroundColor: AppTheme.background, elevation: 0),
            body: Center(child: Text(state.message)),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(backgroundColor: AppTheme.background, elevation: 0),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildHeroSection(FindingModel finding) {
    final String emoji = _getEmoji(finding.type);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           children: [
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
               decoration: BoxDecoration(
                 color: AppTheme.primary.withValues(alpha: 0.1),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Text(emoji, style: const TextStyle(fontSize: 12)),
                   const SizedBox(width: 6),
                   Text(
                     finding.type.toUpperCase(),
                     style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1.0),
                   ),
                 ],
               ),
             ),
             const Spacer(),
             Text(
               _getTimeAgo(finding.foundAt),
               style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
             ),
           ],
        ),
        const SizedBox(height: 16),
        Text(
          finding.headline,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1.0),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => context.push('/watchers/${finding.watcherId}'),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                child: const Center(child: Text('🤖', style: TextStyle(fontSize: 12))),
              ),
              const SizedBox(width: 8),
              Text(
                'Identified by ${finding.watcherName ?? finding.type.toUpperCase()}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(FindingModel finding) {
    final current = finding.data?['current_value'] ?? finding.data?['price'] ?? 'N/A';
    final previous = finding.data?['previous_value'] ?? finding.data?['previous_price'];
    final change = finding.data?['change_percent'] ?? finding.data?['change_amount'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            finding.detail ?? 'No additional analysis provided.', 
            style: const TextStyle(fontSize: 15, height: 1.6, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)
          ),
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
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => launchUrl(Uri.parse(finding.actionUrl!)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget _buildPaymentReceipt(FindingModel finding) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Verification Receipt', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text('ON CHAIN', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildReceiptRow('Agent Deployment Cost', '\$${finding.costUsdc.toStringAsFixed(4)} USDC'),
          _buildReceiptRow('Detection Engine', '${finding.type.toUpperCase()} SCANNER'),
          _buildReceiptRow('Stellar Transaction', finding.stellarTxHash != null 
              ? '${finding.stellarTxHash!.substring(0, 8)}...${finding.stellarTxHash!.substring(finding.stellarTxHash!.length - 8)}' 
              : 'VERIFYING...', 
              onTap: finding.stellarTxHash != null ? () => launchUrl(Uri.parse('https://stellar.expert/explorer/testnet/tx/${finding.stellarTxHash}')) : null),
          _buildReceiptRow('Timestamp', DateFormat('MMM d, HH:mm').format(DateTime.parse(finding.foundAt))),
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
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          InkWell(
            onTap: onTap,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 13, 
                fontFamily: onTap != null ? 'Courier' : null,
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
        const Text("Agent Insights", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('“', style: TextStyle(color: AppTheme.primary, fontSize: 32, fontWeight: FontWeight.w900, height: 0.5)),
              Text(
                finding.data?['agent_reasoning'] ?? 'Based on my specialized training and the constraints you defined, this result matches your target criteria perfectly. Deploying more agents could refine this further. 👻',
                style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.6, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedSection(FindingModel finding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activity Trend', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
        const SizedBox(height: 24),
        Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          ),
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
                      const FlSpot(6, 12), const FlSpot(7, 18), const FlSpot(8, 15),
                   ],
                   isCurved: true,
                   color: AppTheme.primary,
                   barWidth: 4,
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
        return '✨';
    }
  }

  String _getTimeAgo(String foundAt) {
    final date = DateTime.parse(foundAt);
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(date);
  }

  void _shareFinding(FindingModel finding) {
    final text = '👻 Flare Finding: ${finding.headline}\n\n${finding.detail ?? ''}\n\n${finding.actionUrl ?? ''}';
    Share.share(text);
  }
}

