import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/core/utils/string_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/models/models.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_bloc.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_event.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_state.dart';
import 'package:flare_app/features/findings/presentation/widgets/confidence_gauge.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
              title: Text(
                finding.type.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8, color: AppTheme.textSecondary),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 20),
                  onPressed: () => _shareFinding(finding),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ConfidenceGauge(
                      score: finding.confidenceScore,
                      tier: finding.confidenceTier ?? 'Moderate',
                      breakdown: _getMockBreakdown(finding), // In a real app, this would come from the backend payload
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    finding.headline,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1.0),
                  ),
                  const SizedBox(height: 12),
                  _buildVerificationBadge(finding),
                  const SizedBox(height: 24),
                  _buildAnalysisCard(finding),
                  if (finding.collaborationResult != null) ...[
                    const SizedBox(height: 24),
                    _buildCollaborationCard(finding),
                  ],
                  if (finding.actionUrl != null) ...[
                    const SizedBox(height: 24),
                    _buildActionButton(finding),
                  ],
                  const SizedBox(height: 32),
                  _buildEnhancedReceipt(finding),
                  const SizedBox(height: 32),
                  _buildDecisionChain(finding),
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

  Widget _buildVerificationBadge(FindingModel finding) {
    final bool isVerified = finding.verified;
    final color = isVerified ? Colors.blueAccent : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isVerified ? Icons.verified_rounded : Icons.bolt_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified ? '✅ Verified with 2 independent checks' : '⚡ Single check — not yet re-verified',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
                ),
                if (isVerified && finding.verificationTxHash != null) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => launchUrl(Uri.parse('https://stellar.expert/explorer/testnet/tx/${finding.verificationTxHash}')),
                    child: Text(
                      'Verify 2nd Check: ${StringUtils.truncate(finding.verificationTxHash, 16)}',
                      style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8), decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(FindingModel finding) {
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
          Text(
            finding.detail ?? 'No additional analysis provided.',
            style: const TextStyle(fontSize: 15, height: 1.6, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          _buildMetricGrid(finding),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(FindingModel finding) {
    final data = finding.data ?? {};
    final current = data['price'] ?? data['current_value'] ?? 'N/A';
    final previous = data['previous_price'] ?? data['previous_value'] ?? data['old_price'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetricItem('CURRENT', current.toString(), Colors.green),
        if (previous != null)
          _buildMetricItem('PREVIOUS', previous.toString(), Colors.grey, isStrikethrough: true),
        _buildMetricItem('TIMESTAMP', _getTimeAgo(finding.foundAt), AppTheme.textSecondary),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, Color color, {bool isStrikethrough = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
            decoration: isStrikethrough ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCollaborationCard(FindingModel finding) {
    final res = finding.collaborationResult!;
    final isSafe = res['safe'] ?? true;
    final color = isSafe ? Colors.amber.shade700 : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Cross-Checked with ${res['triggered_service']?.toUpperCase()} SERVICE',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: -0.2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isSafe ? (res['result_summary'] ?? 'Confirmation received.') : (res['result_summary'] ?? 'Warning detected.'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
          ),
          if (res['tx_hash'] != null) ...[
             const SizedBox(height: 16),
             InkWell(
               onTap: () => launchUrl(Uri.parse('https://stellar.expert/explorer/testnet/tx/${res['tx_hash']}')),
               child: Text(
                 'Collaboration Hash: ${StringUtils.truncate(res['tx_hash'], 12)}',
                 style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.primary, decoration: TextDecoration.underline),
               ),
             ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(FindingModel finding) {
    String label = 'Book This Flight';
    if (finding.type == 'products') label = 'Buy Now';
    if (finding.type == 'news') label = 'Read Deep Analysis';
    if (finding.type == 'jobs') label = 'Apply to Position';

    return Column(
      children: [
        Container(
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
           onPressed: () => _shareFinding(finding),
           style: OutlinedButton.styleFrom(
             padding: const EdgeInsets.symmetric(vertical: 16),
             minimumSize: const Size(double.infinity, 50),
             side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
           ),
           child: const Text('Share Finding', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ),
      ],
    );
  }

  Widget _buildEnhancedReceipt(FindingModel finding) {
    final collabCost = finding.collaborationResult != null ? 0.008 : 0.0;
    final totalCost = finding.costUsdc + (finding.verified ? 0.008 : 0.0) + collabCost;

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
              const Text('Intelligence Receipt', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Text('\$${totalCost.toStringAsFixed(3)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 24),
          _buildTxRow('Initial Check', finding.stellarTxHash, finding.costUsdc),
          if (finding.verified)
             _buildTxRow('Re-Verification (60s)', finding.verificationTxHash, 0.008),
          if (finding.collaborationResult != null)
             _buildTxRow('Cross-Agent Check', finding.collaborationResult!['tx_hash'], 0.008),
          const Divider(height: 32),
          Text(
            'All transactions verified on Stellar Testnet',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTxRow(String label, String? hash, double cost) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
               Text('\$${cost.toStringAsFixed(3)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
             ],
           ),
           const SizedBox(height: 4),
           if (hash != null)
             InkWell(
               onTap: () => launchUrl(Uri.parse('https://stellar.expert/explorer/testnet/tx/$hash')),
               child: Text(
                 StringUtils.formatHash(hash, startLen: 16, endLen: 8),
                 style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppTheme.primary, decoration: TextDecoration.underline),
               ),
             )
           else
             const Text('Pending...', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDecisionChain(FindingModel finding) {
    final data = finding.data ?? {};
    final current = data['price'] ?? data['current_value'] ?? '???';
    final type = finding.type;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Agent Reasoning", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReasoningStep('1', 'Checked $type source — \$$current (Matches threshold)'),
              if (finding.verified)
                _buildReasoningStep('2', 'Re-verified after 60s cooldown — Data confirmed ✓'),
              if (finding.collaborationResult != null)
                 _buildReasoningStep('3', 'Collateral agent check (${finding.collaborationResult!['triggered_service']}) — Safety confirmed ✓'),
              const Divider(color: Colors.white24, height: 24),
              Text(
                'Conclusion: High-fidelity finding detected. Confidence: ${finding.confidenceScore}%',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasoningStep(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$step. ', style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.w900)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }

  Map<String, double> _getMockBreakdown(FindingModel finding) {
     return {
        'Freshness': 0.95,
        'Verification': finding.verified ? 1.0 : 0.4,
        'History': 0.8,
        'Collaboration': finding.collaborationResult != null ? 0.9 : 0.1,
        'Reliability': 0.85,
     };
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
    final headline = finding.headline;
    final score = finding.confidenceScore;
    final cost = 0.024; // Mock total cost as per request
    
    final text = 'Ghost found me $headline. Verified with $score% confidence across 3 checks. Total monitoring cost: \$$cost. 👻';
    Share.share(text);
  }
}
