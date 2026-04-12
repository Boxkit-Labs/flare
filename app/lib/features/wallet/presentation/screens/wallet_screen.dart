import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/models/models.dart';
import 'package:flare_app/core/widgets/error_state.dart';
import 'package:flare_app/core/widgets/shimmer_utilities.dart';
import 'package:flare_app/core/widgets/top_snackbar.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flare_app/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flare_app/features/wallet/presentation/bloc/wallet_event.dart';
import 'package:flare_app/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:intl/intl.dart';
import 'package:flare_app/core/utils/string_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flare_app/features/wallet/domain/services/savings_service.dart';
import 'package:flare_app/features/wallet/presentation/widgets/spending_heatmap.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_bloc.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_state.dart';

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

  void _refresh({bool force = false}) {
    final walletState = context.read<WalletBloc>().state;
    if (!force && walletState is WalletLoaded && walletState.wallet != null) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final userId = authState.user.userId;
      context.read<WalletBloc>().add(LoadAllWalletData(userId, isRefresh: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: const Text(
          'Wallet',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.8),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () {

            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
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
        color: AppTheme.primary,
        onRefresh: () async {
          _refresh(force: true);
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildBalanceHeader(state.wallet),
            const SizedBox(height: 32),
            _buildTodayStats(state.stats),
            const SizedBox(height: 32),
            _buildSpendingChart(state.stats),
            const SizedBox(height: 32),
            _buildWatcherBreakdown(state.stats),
            const SizedBox(height: 32),
            _buildSavingsDashboard(context, state),
            const SizedBox(height: 32),
            _buildEfficiencyCard(state.transactions ?? []),
            const SizedBox(height: 32),
            _buildHeatmap(context, state),
            const SizedBox(height: 32),
            _buildTransactionHistory(state.transactions),
            const SizedBox(height: 100),

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const Center(
          child: Column(
            children: [
              ShimmerPlaceholder(width: 150, height: 16),
              SizedBox(height: 12),
              ShimmerPlaceholder(width: 200, height: 60),
              SizedBox(height: 24),
              ShimmerPlaceholder(width: 140, height: 48, borderRadius: 24),
            ],
          ),
        ),
        const SizedBox(height: 48),
        const ShimmerGrid(itemCount: 3, itemHeight: 80, padding: EdgeInsets.zero),
        const SizedBox(height: 48),
        const ShimmerPlaceholder(width: 150, height: 24),
        const SizedBox(height: 24),
        const ShimmerPlaceholder(width: double.infinity, height: 200, borderRadius: 28),
        const SizedBox(height: 48),
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
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: balance),
          duration: const Duration(seconds: 1),
          curve: Curves.easeOutQuart,
          builder: (context, value, child) {
            return Text(
              StringUtils.formatCurrency(value, decimals: 4),
              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, letterSpacing: -2.0),
            );
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthAuthenticated) {
                    context.read<WalletBloc>().add(FundWalletUser(authState.user.userId));
                    TopSnackbar.showSuccess(context, 'Requesting Testnet funds...');
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                label: const Text('Add Funds', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: address));
            TopSnackbar.showSuccess(context, 'Address copied!');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  StringUtils.formatHash(address),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.copy_rounded, size: 14, color: AppTheme.primary),
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
          'SPENT TODAY',
          StringUtils.formatCurrency(stats?.spentToday ?? 0.0, decimals: 3),
          Icons.arrow_downward_rounded,
        ),
        const SizedBox(width: 12),
        _buildStatPill(
          'AGENT CHECKS',
          '${stats?.totalChecksToday ?? 0}',
          Icons.bolt_rounded,
        ),
        const SizedBox(width: 12),
        _buildStatPill(
          'NEW FINDINGS',
          '${stats?.totalFindingsToday ?? 0}',
          Icons.auto_awesome_rounded,
          isHighlight: true,
        ),
      ],
    );
  }

  Widget _buildStatPill(
    String label,
    String value,
    IconData icon, {
    bool isHighlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isHighlight
                ? AppTheme.primary.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
          ),
          boxShadow: [
             BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: isHighlight ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5),
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
              'Spending Trend',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
            ),
            Container(
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7D', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  ButtonSegment(value: 30, label: Text('30D', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
                selected: {_chartDays},
                onSelectionChanged: (set) =>
                    setState(() => _chartDays = set.first),
                style: SegmentedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  selectedBackgroundColor: AppTheme.primary,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 6),
            const Text('On-chain', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 6),
            const Text('MPP Channels', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          height: 220,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          ),
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
    return List.generate(_chartDays, (index) {
      final isLast = index == _chartDays - 1;
      final blueValue = 0.03 + (index % 3) * 0.010;
      final purpleValue = 0.01 + (index % 5) * 0.015;
      final totalY = blueValue + purpleValue;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: totalY,
            width: 14,
            borderRadius: BorderRadius.circular(4),
            color: Colors.transparent,
            rodStackItems: [
               BarChartRodStackItem(0.0, blueValue, isLast ? Colors.blue : Colors.blue.withValues(alpha: 0.4)),
               BarChartRodStackItem(blueValue, totalY, isLast ? Colors.purple : Colors.purple.withValues(alpha: 0.4)),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildWatcherBreakdown(SpendingStatsModel? stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Operational Allocation',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          ),
          child: Column(
            children: [
              _buildWatcherRow('✈️ Tokyo Trip', '\$0.42', 45, Colors.blue),
              const Divider(height: 24, color: AppTheme.background),
              _buildWatcherRow('💰 Bitcoin Alert', '\$0.28', 30, Colors.purple),
              const Divider(height: 24, color: AppTheme.background),
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
             Container(
               height: 6,
               width: double.infinity,
               decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(3)),
             ),
             Container(
               height: 6,
               width: (MediaQuery.of(context).size.width - 88) * (percent / 100),
               decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
             ),
          ],
        ),
      ],
    );
  }

  Widget _buildEfficiencyCard(List<TransactionModel> txs) {
    if (txs.isEmpty) return const SizedBox.shrink();

    final offChainCount = txs.where((t) => t.isOffChain).length;
    final onChainCount = txs.where((t) => !t.isOffChain).length;

    final withMppTx = onChainCount;
    final withoutMppTx = onChainCount + offChainCount;
    final savedPercent = withoutMppTx > 0 ? ((offChainCount / withoutMppTx) * 100).round() : 0;

    final channelsOpened = txs.where((t) => t.txType == 'channel_open' || (t.channelId != null && t.channelId!.isNotEmpty)).map((t) => t.channelId).toSet().length;
    final activeChannels = channelsOpened > 0 ? 1 : 0;
    final settledChannels = channelsOpened > 0 ? channelsOpened - activeChannels : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Efficiency',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
        ),
        const SizedBox(height: 20),
        Container(
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
                  const Text('Without MPP:', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('$withoutMppTx transactions', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('With MPP:', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('$withMppTx transactions', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.blue)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Saved:', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('$savedPercent% fewer tx', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.purple)),
                ],
              ),
              const SizedBox(height: 24),

              Stack(
                children: [
                   Container(
                     height: 14,
                     width: double.infinity,
                     decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(7)),
                   ),
                   Container(
                     height: 14,
                     width: (MediaQuery.of(context).size.width - 88) * (withMppTx / (withoutMppTx > 0 ? withoutMppTx : 1)),
                     decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(7)),
                   ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text('$withMppTx/$withoutMppTx on-chain', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              ),
              const SizedBox(height: 24),
              const Divider(color: AppTheme.background),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildChannelStat('Opened', channelsOpened.toString()),
                  _buildChannelStat('Settled', settledChannels.toString()),
                  _buildChannelStat('Active', activeChannels.toString(), isHighlight: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelStat(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isHighlight ? Colors.purple : Colors.black)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildChannelHistorySection(List<TransactionModel>? transactions) {
     if (transactions == null || transactions.isEmpty) return const SizedBox.shrink();

     final offChain = transactions.where((t) => t.isOffChain && t.channelId != null).toList();
     if (offChain.isEmpty) return const SizedBox.shrink();

     final Map<String, List<TransactionModel>> channelGroups = {};
     for (var tx in offChain) {
        if (!channelGroups.containsKey(tx.channelId!)) {
           channelGroups[tx.channelId!] = [];
        }
        channelGroups[tx.channelId!]!.add(tx);
     }

     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         const Text(
            'Channel History',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
         ),
         const SizedBox(height: 16),
         ...channelGroups.entries.map((entry) {
             final channelId = entry.key;
             final channelTxs = entry.value;
             final depositAmount = (channelTxs.length * 0.005).toStringAsFixed(3);
             final totalSpent = channelTxs.fold(0.0, (sum, tx) => sum + tx.amountUsdc);

             const isClosed = false;

             return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purple.withValues(alpha: 0.1), width: 1.5),
                ),
                child: ExpansionTile(
                   collapsedIconColor: Colors.purple,
                   iconColor: Colors.purple,
                   shape: const RoundedRectangleBorder(side: BorderSide.none),
                   title: Text(
                     channelTxs.first.watcherName ?? 'MPP Channel',
                     style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                   ),
                   subtitle: Text('${channelTxs.length} checks · $channelId', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                   children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                              _buildDetailRow('STATUS', isClosed ? 'CLOSED' : 'OPEN', isCopyable: false),
                              _buildDetailRow('DEPOSIT', '\$$depositAmount USDC'),
                              _buildDetailRow('DURATION', 'Open for 1h 22m'),
                              _buildDetailRow('EFFICIENCY', '${channelTxs.length} checks via 2 on-chain tx'),
                              _buildDetailRow('TOTAL SPENT', '\$${totalSpent.toStringAsFixed(3)} USDC'),
                              _buildDetailRow('OPEN TX', 'Loading...', isCopyable: true),
                           ]
                        )
                      )
                   ],
                )
             );
         }),
         const SizedBox(height: 32),
       ],
     );
  }

  Widget _buildTransactionHistory(List<TransactionModel>? transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChannelHistorySection(transactions),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Activity Ledger',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (transactions == null || transactions.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Text('📜', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  const Text(
                    'No transaction activity',
                    style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        else
          ...transactions.where((t) => !t.isOffChain).map((tx) => _buildTransactionTile(tx)),
      ],
    );
  }

  Widget _buildTransactionTile(TransactionModel tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: ListTile(
        onTap: () => _showTransactionDetail(tx),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
             color: AppTheme.background,
             borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              _getEmojiByServiceName(tx.serviceName),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        title: Text(
          tx.watcherName ?? tx.serviceName,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -0.3),
        ),
        subtitle: Text(
          DateFormat('MMM d, HH:mm').format(DateTime.parse(tx.timestamp)),
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '-\$${tx.amountUsdc.toStringAsFixed(4)}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black),
            ),
            if (tx.findingDetected == true)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: const Text('DETECTED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.amber)),
              ),
          ],
        ),
      ),
    );
  }

  String _getEmojiByServiceName(String service) {
     final s = service.toLowerCase();
     if (s.contains('flight')) return '✈️';
     if (s.contains('crypto')) return '💰';
     if (s.contains('news')) return '📰';
     if (s.contains('product')) return '🛍️';
     if (s.contains('job')) return '💼';
     return '🤖';
  }

  void _showTransactionDetail(TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
               child: Container(
                 width: 40,
                 height: 4,
                 decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
               ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Transaction Receipt',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.8),
            ),
            const SizedBox(height: 32),
            _buildDetailRow('AGENT NAME', tx.watcherName ?? 'General Scanner'),
            _buildDetailRow('SERVICE LAYER', tx.serviceName.toUpperCase()),
            _buildDetailRow('AMOUNT', '\$${tx.amountUsdc.toStringAsFixed(4)} USDC'),
            _buildDetailRow('TIMESTAMP', DateFormat('MMMM d, yyyy HH:mm').format(DateTime.parse(tx.timestamp))),
            _buildDetailRow('STELLAR HASH', tx.stellarTxHash, isCopyable: true),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.rocket_launch_rounded, size: 18, color: Colors.white),
                onPressed: () {
                  final url = 'https://stellar.expert/explorer/testnet/tx/${tx.stellarTxHash}';
                  launchUrl(Uri.parse(url));
                },
                label: const Text('View on Stellar Expert', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(width: 24),
          Expanded(
            child: InkWell(
              onTap: isCopyable
                  ? () {
                      Clipboard.setData(ClipboardData(text: value));
                      TopSnackbar.showSuccess(context, 'Copied!');
                    }
                  : null,
              child: Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  fontFamily: isCopyable ? 'Courier' : null,
                  color: isCopyable ? AppTheme.primary : AppTheme.textPrimary,
                  decoration: isCopyable ? TextDecoration.underline : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsDashboard(BuildContext context, WalletLoaded state) {
    return BlocBuilder<FindingsBloc, FindingsState>(
      builder: (context, findingsState) {
        if (findingsState is FindingsLoaded) {
          final savings = SavingsService.calculateTotalSavings(findingsState.findings);
          final totalS = savings['total'] ?? 0.0;
          final totalSpent = state.stats?.totalSpentAllTime ?? 0.0;
          final roi = SavingsService.calculateROI(totalS, totalSpent);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Financial Performance',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL SAVED BY GHOST', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    const SizedBox(height: 12),
                    Text(
                      '\$${totalS.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -2.0),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildRatioItem('Total Spent', '\$${totalSpent.toStringAsFixed(2)}'),
                        _buildRatioItem('ROI', 'x${roi.round()}'),
                        _buildRatioItem('Time Saved', '${(state.stats?.totalChecksToday ?? 0) * 2}min'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildCategorySavings(savings['byCategory']),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRatioItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildCategorySavings(Map<String, double> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categories.entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_getCategoryEmoji(e.key), style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(
                '\$${e.value.round()}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getCategoryEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'flights': return '✈️';
      case 'products': return '🛍️';
      case 'crypto': return '💰';
      case 'sports': return '⚽';
      default: return '✨';
    }
  }

  Widget _buildHeatmap(BuildContext context, WalletLoaded state) {
    return SpendingHeatmap(
      dailySpending: state.stats?.dailySpending ?? [],
      onDayTap: (day) => _showDayDetail(context, day),
    );
  }

  void _showDayDetail(BuildContext context, Map<String, dynamic> day) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
               child: Container(
                 width: 40, height: 4,
                 decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
               ),
            ),
            const SizedBox(height: 32),
            Text(
              DateFormat('MMMM d, yyyy').format(DateTime.parse(day['date'])),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.8),
            ),
            const SizedBox(height: 32),
            _buildDetailRowItem('TOTAL SPENT', '\$${(day['amount'] ?? 0.0).toStringAsFixed(3)} USDC'),
            _buildDetailRowItem('FINDINGS DETECTED', '${day['findings'] ?? 0} FINDINGS', isHighlighted: (day['findings'] ?? 0) > 0),
            _buildDetailRowItem('ACTIVITY LEVEL', (day['amount'] ?? 0) > 0.05 ? 'HIGH' : 'MODERATE'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRowItem(String label, String value, {bool isHighlighted = false}) {
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 10),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
           Text(
             value,
             style: TextStyle(
               fontWeight: FontWeight.w900,
               fontSize: 14,
               color: isHighlighted ? AppTheme.primary : AppTheme.textPrimary,
             ),
           ),
         ],
       ),
     );
  }
}

