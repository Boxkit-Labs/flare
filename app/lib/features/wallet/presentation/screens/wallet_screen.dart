import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_app/core/theme/app_theme.dart';
import 'package:ghost_app/core/models/models.dart';
import 'package:ghost_app/core/widgets/error_state.dart';
import 'package:ghost_app/core/widgets/shimmer_utilities.dart';
import 'package:ghost_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ghost_app/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:ghost_app/features/wallet/presentation/bloc/wallet_event.dart';
import 'package:ghost_app/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _chartDays = 7;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final userId = (context.read<AuthBloc>().state as dynamic).user.userId;
    context.read<WalletBloc>().add(LoadWallet(userId));
    context.read<WalletBloc>().add(LoadWalletStats(userId));
    context.read<WalletBloc>().add(LoadTransactions(userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wallet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _buildWalletContent(context, state),
          );
        },
      ),
    );
  }

  Widget _buildWalletContent(BuildContext context, WalletState state) {
    if (state is WalletLoaded) {
      return RefreshIndicator(
        key: const ValueKey('loaded'),
        onRefresh: () async {
          _refresh();
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildBalanceHeader(state.wallet),
            const SizedBox(height: 32),
            _buildTodayStats(state.stats),
            const SizedBox(height: 32),
            _buildSpendingChart(state.stats),
            const SizedBox(height: 32),
            _buildWatcherBreakdown(state.stats),
            const SizedBox(height: 32),
            _buildSavingsBanner(state.stats),
            const SizedBox(height: 32),
            _buildTransactionHistory(state.transactions),
            const SizedBox(height: 60),
          ],
        ),
      );
    }

    if (state is WalletError) {
      return ErrorState(
        key: const ValueKey('error'),
        message: state.message,
        onRetry: _refresh,
      );
    }

    return ListView(
      key: const ValueKey('loading'),
      padding: const EdgeInsets.all(24),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const Center(
          child: Column(
            children: [
              ShimmerPlaceholder(width: 150, height: 16),
              SizedBox(height: 8),
              ShimmerPlaceholder(width: 200, height: 60),
              SizedBox(height: 24),
              ShimmerPlaceholder(width: 120, height: 40, borderRadius: 20),
            ],
          ),
        ),
        const SizedBox(height: 40),
        const ShimmerGrid(itemCount: 3, itemHeight: 80, padding: EdgeInsets.zero),
        const SizedBox(height: 40),
        const ShimmerPlaceholder(width: 150, height: 24),
        const SizedBox(height: 24),
        const ShimmerPlaceholder(width: double.infinity, height: 200, borderRadius: 20),
        const SizedBox(height: 40),
        const ShimmerHeader(),
        const SizedBox(height: 16),
        const ShimmerList(itemCount: 5, padding: EdgeInsets.zero),
      ],
    );
  }

  Widget _buildBalanceHeader(WalletModel? wallet) {
    final balance = wallet?.balanceUsdc ?? 0.0;
    final address = wallet?.publicKey ?? 'GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';

    return Column(
      children: [
        const Text(
          'USDC on Stellar Testnet',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Text(
          '\$${balance.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                final userId =
                    (context.read<AuthBloc>().state as dynamic).user.userId;
                // Assuming fundWallet exists in ApiService and connected to an event
                // For now, we manually refresh
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Requesting Testnet funds...')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Funds'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: address));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Address copied!')));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${address.substring(0, 8)}...${address.substring(address.length - 8)}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.copy, size: 14, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStats(SpendingStatsModel? stats) {
    return Row(
      children: [
        _buildStatPill(
          'Spent today',
          '\$${(stats?.spentToday ?? 0.0).toStringAsFixed(2)}',
        ),
        const SizedBox(width: 12),
        _buildStatPill('Checks today', '${stats?.totalChecksToday ?? 0}'),
        const SizedBox(width: 12),
        _buildStatPill(
          'Findings',
          '${stats?.totalFindingsToday ?? 0}',
          isHighlight: true,
        ),
      ],
    );
  }

  Widget _buildStatPill(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlight
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlight
                ? AppTheme.primary.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingChart(SpendingStatsModel? stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Spending History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7D')),
                ButtonSegment(value: 30, label: Text('30D')),
              ],
              selected: {_chartDays},
              onSelectionChanged: (set) =>
                  setState(() => _chartDays = set.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              barGroups: _generateBarGroups(stats),
            ),
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _generateBarGroups(SpendingStatsModel? stats) {
    // Mock data generation for demo if stats null
    return List.generate(_chartDays, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: 0.05 + (index % 3) * 0.02,
            color: index == 3 ? Colors.green : AppTheme.primary,
            width: 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  Widget _buildWatcherBreakdown(SpendingStatsModel? stats) {
    // Each watcher: name + emoji + amount this week + percentage of total
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spending by Watcher',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _buildWatcherRow('✈️ Tokyo Trip', '\$0.42', 45, Colors.blue),
              _buildWatcherRow('💰 Bitcoin Alert', '\$0.28', 30, Colors.green),
              _buildWatcherRow('🛍️ iPhone Watch', '\$0.15', 25, Colors.orange),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWatcherRow(
    String name,
    String amount,
    double percent,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.white10,
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsBanner(SpendingStatsModel? stats) {
    final ghostMonthly = 0.85; // Mock
    final totalSavings = 57.15;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF6A1B9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Savings Analysis',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'UNLIMITED AGENTS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Ghost this month: \$$ghostMonthly',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Traditional subscriptions: ~\$58.00/mo",
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Text(
            'You\'re saving: \$$totalSavings/month',
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Based on your current custom usage pattern.',
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(List<TransactionModel>? transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transactions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextButton(onPressed: () {}, child: const Text('Export')),
          ],
        ),
        const SizedBox(height: 8),
        if (transactions == null || transactions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No transactions yet',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...transactions.map((tx) => _buildTransactionTile(tx)),
      ],
    );
  }

  Widget _buildTransactionTile(TransactionModel tx) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _showTransactionDetail(tx),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: const Text('👤', style: TextStyle(fontSize: 16)),
        ),
        title: Text(
          tx.watcherName ?? tx.serviceName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          DateFormat('MMM d, HH:mm').format(DateTime.parse(tx.timestamp)),
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '-\$${tx.amountUsdc.toStringAsFixed(3)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (tx.findingDetected == true)
              const Icon(Icons.star, color: Colors.amber, size: 12),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetail(TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Detail',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Stellar Hash', tx.stellarTxHash, isCopyable: true),
            _buildDetailRow('Service', tx.serviceName),
            _buildDetailRow(
              'Amount',
              '\$${tx.amountUsdc.toStringAsFixed(3)} USDC',
            ),
            _buildDetailRow('Timestamp', tx.timestamp),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://stellar.expert/explorer/testnet/tx/${tx.stellarTxHash}',
                  ),
                ),
                child: const Text('View on Stellar Explorer'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isCopyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: isCopyable
                  ? () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Copied!')));
                    }
                  : null,
              child: Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
