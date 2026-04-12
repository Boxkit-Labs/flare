import 'package:flare_app/core/config/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/models/models.dart';
import 'package:flare_app/core/mixins/auto_refresh_mixin.dart';
import 'package:flare_app/core/widgets/error_state.dart';
import 'package:flare_app/core/widgets/shimmer_utilities.dart';
import 'package:flare_app/core/widgets/status_indicator.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_bloc.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_event.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_state.dart';
import 'package:flare_app/features/watchers/presentation/widgets/check_history_tile.dart';
import 'package:flare_app/features/watchers/presentation/widgets/analytics_chart.dart';
import 'package:flare_app/features/watchers/presentation/widgets/animated_budget_bar.dart';
import 'package:flare_app/features/findings/presentation/widgets/finding_card.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fl_chart/fl_chart.dart';

class WatcherDetailScreen extends StatefulWidget {
  final String watcherId;

  const WatcherDetailScreen({super.key, required this.watcherId});

  @override
  State<WatcherDetailScreen> createState() => _WatcherDetailScreenState();
}

class _WatcherDetailScreenState extends State<WatcherDetailScreen>
    with TickerProviderStateMixin, AutoRefreshMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _refresh();
    startAutoRefresh(const Duration(seconds: 30), _onAutoRefresh);
  }

  void _refresh({bool silent = false}) {
    context.read<WatchersBloc>().add(
      LoadWatcherDetail(widget.watcherId, isRefresh: silent),
    );
  }

  void _onAutoRefresh() => _refresh(silent: true);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WatchersBloc, WatchersState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, WatchersState state) {
    if (state is WatcherDetailLoaded &&
        state.watcher.watcherId == widget.watcherId) {
      final watcher = state.watcher;
      return Scaffold(
        backgroundColor: AppTheme.background,
        key: const ValueKey('loaded'),
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(
            watcher.name,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  context.push('/watchers/${watcher.watcherId}/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.more_horiz_rounded),
              onPressed: () => _showOptions(context, watcher),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async {
            _refresh();
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(watcher),
                const SizedBox(height: 24),
                _buildStatsGrid(watcher),
                const SizedBox(height: 32),
                _buildBudgetCard(watcher),
                const SizedBox(height: 32),
                _buildTabBar(watcher),
                const SizedBox(height: 20),
                _buildTabContent(watcher),
              ],
            ),
          ),
        ),
      );
    }

    if (state is WatchersError) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        key: const ValueKey('error'),
        appBar: AppBar(backgroundColor: AppTheme.background, elevation: 0),
        body: ErrorState(message: state.message, onRetry: _refresh),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      key: const ValueKey('loading'),
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const ShimmerPlaceholder(width: 120, height: 20),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const ShimmerPlaceholder(
              width: double.infinity,
              height: 110,
              borderRadius: 24,
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(
                  child: ShimmerPlaceholder(
                    width: double.infinity,
                    height: 80,
                    borderRadius: 16,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ShimmerPlaceholder(
                    width: double.infinity,
                    height: 80,
                    borderRadius: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const ShimmerPlaceholder(
              width: double.infinity,
              height: 100,
              borderRadius: 24,
            ),
            const SizedBox(height: 32),
            const ShimmerHeader(),
            const SizedBox(height: 16),
            const ShimmerList(
              itemCount: 3,
              itemHeight: 80,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(WatcherModel watcher) {
    final bool isActive = watcher.status == 'active';
    final bool isPaused = watcher.status == 'paused';
    final bool isError = watcher.status == 'error';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      (isError
                              ? Colors.red
                              : (isPaused ? Colors.orange : Colors.green))
                          .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: StatusIndicator(status: watcher.status, size: 10),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      watcher.status.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.2,
                        color: isError
                            ? Colors.red
                            : (isPaused ? Colors.orange : Colors.green),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActive
                          ? 'Hunting for data since ${DateFormat('MMM d').format(DateTime.parse(watcher.createdAt))}'
                          : isPaused
                          ? 'Agent currently sleeping'
                          : 'Something went wrong',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (['crypto', 'stock'].contains(watcher.type) && isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        color: Colors.redAccent,
                        size: 10,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              if (isError)
                TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                ),
            ],
          ),
          if (isError && watcher.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                watcher.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(WatcherModel watcher) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildStatCard(
          'Total Checks',
          '${watcher.totalChecks}',
          Icons.analytics_outlined,
        ),
        _buildStatCard(
          'Findings',
          '${watcher.totalFindings}',
          Icons.bolt_rounded,
        ),
        _buildStatCard(
          'Total Spent',
          '\$${watcher.totalSpentUsdc.toStringAsFixed(2)}',
          Icons.payment_rounded,
        ),
        _buildStatCard(
          'Budget Status',
          '${(watcher.budgetPercentUsed! * 100).toInt()}%',
          Icons.account_balance_wallet_outlined,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(WatcherModel watcher) {
    final percentUsed = watcher.budgetPercentUsed ?? 0.0;

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
              const Text(
                'Weekly Budget',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '\$${watcher.spentThisWeekUsdc.toStringAsFixed(2)} / \$${watcher.weeklyBudgetUsdc.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBudgetBar(percentUsed: percentUsed, minHeight: 10),
          const SizedBox(height: 12),
          Text(
            'Resets in ${7 - DateTime.now().weekday % 7} days',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(WatcherModel watcher) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: AppTheme.primaryGradient,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        padding: const EdgeInsets.all(4),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Live Feed'),
          Tab(text: 'Findings'),
          Tab(text: 'History'),
          Tab(text: 'Charts'),
        ],
      ),
    );
  }

  Widget _buildTabContent(WatcherModel watcher) {
    return SizedBox(
      height: 500,
      child: TabBarView(
        controller: _tabController,
        children: [
          _LiveFeedTab(watcher: watcher),
          _buildFindingsTab(watcher),
          _buildHistoryTab(watcher),
          _buildAnalyticsTab(watcher),
        ],
      ),
    );
  }

  Widget _buildFindingsTab(WatcherModel watcher) {
    final findings = watcher.recentFindings ?? [];
    if (findings.isEmpty) {
      return _buildEmptyTab(
        'No findings yet',
        'Your agent hasn\'t discovered any matches.',
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: findings.length,
      itemBuilder: (context, index) => FindingCard(finding: findings[index]),
    );
  }

  Widget _buildHistoryTab(WatcherModel watcher) {
    final checks = watcher.recentChecks ?? [];
    if (checks.isEmpty) {
      return _buildEmptyTab(
        'No history',
        'Agent is awaiting its first deployment check.',
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: checks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => CheckHistoryTile(check: checks[index]),
    );
  }

  Widget _buildAnalyticsTab(WatcherModel watcher) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Expanded(child: AnalyticsChart(watcher: watcher)),
          const SizedBox(height: 16),
          const Text(
            'Activity levels over the last 24 hours',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🛡️', style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, WatcherModel watcher) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    watcher.status == 'active'
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    color: AppTheme.primary,
                  ),
                ),
                title: Text(
                  watcher.status == 'active'
                      ? 'Pause Watcher'
                      : 'Resume Watcher',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  context.read<WatchersBloc>().add(
                    ToggleWatcher(watcher.watcherId),
                  );
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                title: const Text(
                  'Delete Watcher',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  context.read<WatchersBloc>().add(
                    DeleteWatcher(watcher.watcherId),
                  );
                  Navigator.pop(context);
                  context.pop(); // Go back to list
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveFeedTab extends StatefulWidget {
  final WatcherModel watcher;
  const _LiveFeedTab({required this.watcher});

  @override
  State<_LiveFeedTab> createState() => _LiveFeedTabState();
}

class _LiveFeedTabState extends State<_LiveFeedTab> {
  WebSocketChannel? _channel;
  final List<double> _prices = [];
  Map<String, dynamic>? _latestFrame;
  bool _isConnected = false;
  bool _isReconnecting = false;
  int _proofsSent = 0;

  @override
  void initState() {
    super.initState();
    if (['crypto', 'stock'].contains(widget.watcher.type)) {
      _connect();
    }
  }

  void _connect() {
    try {
      if (!mounted) return;
      setState(() {
        _isReconnecting = true;
      });
      final wsUrl =
          '${AppConstants.baseWsUrl}/ws/stream?watcherId=${widget.watcher.watcherId}&userId=${widget.watcher.userId}';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          if (data['type'] == 'data') {
            if (!mounted) return;
            setState(() {
              _isConnected = true;
              _isReconnecting = false;
              _latestFrame = data;
              final num val = data['payload']['price'] ?? 0.0;
              _prices.add(val.toDouble());
              if (_prices.length > 20) _prices.removeAt(0);
              _proofsSent++;
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isConnected = false;
              _isReconnecting = true;
            });
            Future.delayed(const Duration(seconds: 3), _connect);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isConnected = false;
              _isReconnecting = true;
            });
            Future.delayed(const Duration(seconds: 3), _connect);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isReconnecting = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!['crypto', 'stock'].contains(widget.watcher.type)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.waves, size: 40, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Live Stream Unavailable',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'High-frequency WebSocket streams are\ncurrently only supported for crypto/stocks.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final price = _latestFrame != null
        ? _latestFrame!['payload']['price'].toString()
        : '---';
    final timestamp = _latestFrame != null
        ? DateFormat('HH:mm:ss.SS').format(DateTime.now())
        : '--:--:--';
    final sessionCost = (_proofsSent * 0.0005).toStringAsFixed(4);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isConnected ? Colors.green : Colors.amber,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isConnected ? Colors.green : Colors.amber)
                              .withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isConnected ? 'Connected' : 'Reconnecting...',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                timestamp,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'LATEST FRAME',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$$price',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        'USD',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 100,
                  child: _prices.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white24,
                          ),
                        )
                      : LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _prices
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => FlSpot(e.key.toDouble(), e.value),
                                    )
                                    .toList(),
                                isCurved: true,
                                color: Colors.greenAccent,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.greenAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.link, color: Colors.purple, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Proofs sent: $_proofsSent  |  Session cost: \$$sessionCost',
                  style: const TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
