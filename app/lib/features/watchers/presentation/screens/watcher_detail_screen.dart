import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_app/core/theme/app_theme.dart';
import 'package:ghost_app/core/models/models.dart';
import 'package:ghost_app/features/watchers/presentation/bloc/watchers_bloc.dart';
import 'package:ghost_app/features/watchers/presentation/bloc/watchers_event.dart';
import 'package:ghost_app/features/watchers/presentation/bloc/watchers_state.dart';
import 'package:ghost_app/features/watchers/presentation/widgets/check_history_tile.dart';
import 'package:ghost_app/features/watchers/presentation/widgets/analytics_chart.dart';
import 'package:ghost_app/features/findings/presentation/widgets/finding_card.dart';

class WatcherDetailScreen extends StatefulWidget {
  final String watcherId;

  const WatcherDetailScreen({super.key, required this.watcherId});

  @override
  State<WatcherDetailScreen> createState() => _WatcherDetailScreenState();
}

class _WatcherDetailScreenState extends State<WatcherDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refresh();
  }

  void _refresh() {
    context.read<WatchersBloc>().add(LoadWatcherDetail(widget.watcherId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WatchersBloc, WatchersState>(
      builder: (context, state) {
        if (state is WatcherDetailLoaded && state.watcher.watcherId == widget.watcherId) {
          final watcher = state.watcher;
          return Scaffold(
            appBar: AppBar(
              title: Text(watcher.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                     // TODO: Navigate to Edit screen
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showOptions(context, watcher),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                _refresh();
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusHeader(watcher),
                    const SizedBox(height: 24),
                    _buildStatsRow(watcher),
                    const SizedBox(height: 32),
                    _buildBudgetBar(watcher),
                    const SizedBox(height: 32),
                    _buildTabs(watcher),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is WatchersError) {
           return Scaffold(
             appBar: AppBar(),
             body: Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Text(state.message),
                   const SizedBox(height: 16),
                   ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
                 ],
               ),
             ),
           );
        }

        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildStatusHeader(WatcherModel watcher) {
    final bool isActive = watcher.status == 'active';
    final bool isPaused = watcher.status == 'paused';
    final bool isError = watcher.status == 'error';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _PulsingIndicator(isActive: isActive, color: isError ? Colors.red : (isPaused ? Colors.yellow : Colors.green)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  watcher.status.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 18, 
                    color: isError ? Colors.red : (isPaused ? Colors.yellow : Colors.green),
                  ),
                ),
                if (isPaused)
                   const Text('Manually paused by user', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                if (isError)
                   Text(watcher.errorMessage ?? 'Unexpected error occurred', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                if (isActive)
                   const Text('Agent is hunting... 👻', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          if (isError)
             ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildStatsRow(WatcherModel watcher) {
    final percentUsed = watcher.budgetPercentUsed ?? 0.0;
    final budgetColor = percentUsed < 0.5 ? Colors.green : (percentUsed < 0.8 ? Colors.yellow : Colors.red);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem('Checks', '${watcher.totalChecks}', null),
        _buildStatItem('Findings', '${watcher.totalFindings}', null),
        _buildStatItem('Spent', '\$${watcher.totalSpentUsdc.toStringAsFixed(2)}', null),
        _buildStatItem('Budget Left', '\$${(watcher.weeklyBudgetUsdc - watcher.spentThisWeekUsdc).toStringAsFixed(2)}', budgetColor),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color? valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildBudgetBar(WatcherModel watcher) {
    final percentUsed = watcher.budgetPercentUsed ?? 0.0;
    final budgetColor = percentUsed < 0.5 ? Colors.green : (percentUsed < 0.8 ? Colors.yellow : Colors.red);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             const Text('Weekly Budget', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
             Text('\$${watcher.spentThisWeekUsdc.toStringAsFixed(2)} / \$${watcher.weeklyBudgetUsdc.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
           ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentUsed.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[850],
            valueColor: AlwaysStoppedAnimation<Color>(budgetColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(WatcherModel watcher) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Findings'),
            Tab(text: 'History'),
            Tab(text: 'Analytics'),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 600, // Fixed height for list interaction
          child: TabBarView(
            controller: _tabController,
            children: [
               _buildFindingsTab(watcher),
               _buildHistoryTab(watcher),
               AnalyticsChart(watcher: watcher),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFindingsTab(WatcherModel watcher) {
    final findings = watcher.recentFindings ?? [];
    if (findings.isEmpty) {
      return const Center(child: Text('No findings yet for this watcher', style: TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: findings.length,
      itemBuilder: (context, index) => FindingCard(finding: findings[index]),
    );
  }

  Widget _buildHistoryTab(WatcherModel watcher) {
    final checks = watcher.recentChecks ?? [];
    if (checks.isEmpty) {
      return const Center(child: Text('No check history yet', style: TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: checks.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
      itemBuilder: (context, index) => CheckHistoryTile(check: checks[index]),
    );
  }

  void _showOptions(BuildContext context, WatcherModel watcher) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(watcher.status == 'active' ? Icons.pause_circle_outline : Icons.play_circle_outline),
              title: Text(watcher.status == 'active' ? 'Pause Watcher' : 'Resume Watcher'),
              onTap: () {
                context.read<WatchersBloc>().add(ToggleWatcher(watcher.watcherId));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.orange),
              title: const Text('Delete Watcher', style: TextStyle(color: Colors.orange)),
              onTap: () {
                context.read<WatchersBloc>().add(DeleteWatcher(watcher.watcherId));
                Navigator.pop(context);
                context.pop(); // Go back to list
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingIndicator extends StatefulWidget {
  final bool isActive;
  final Color color;

  const _PulsingIndicator({required this.isActive, required this.color});

  @override
  State<_PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<_PulsingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 1), vsync: this)..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Container(width: 12, height: 12, decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.5), shape: BoxShape.circle));
    }
    return FadeTransition(opacity: _animation, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)));
  }
}
