import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_app/core/theme/app_theme.dart';
import 'package:ghost_app/core/widgets/shimmer_placeholder.dart';
import 'package:ghost_app/features/watchers/presentation/bloc/watchers_bloc.dart';
import 'package:ghost_app/features/watchers/presentation/bloc/watchers_state.dart';
import 'package:ghost_app/features/watchers/presentation/widgets/watcher_card.dart';
import 'package:ghost_app/features/findings/presentation/bloc/findings_bloc.dart';
import 'package:ghost_app/features/findings/presentation/bloc/findings_state.dart';
import 'package:ghost_app/features/findings/presentation/widgets/finding_card.dart';
import 'package:ghost_app/features/briefing/presentation/bloc/briefing_bloc.dart';
import 'package:ghost_app/features/briefing/presentation/bloc/briefing_state.dart';
import 'package:ghost_app/features/briefing/presentation/bloc/briefing_event.dart';
import 'package:ghost_app/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:ghost_app/features/wallet/presentation/bloc/wallet_state.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── TOP SECTION: Greeting + Wallet ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const Text(
                      'Ready to hunt',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                BlocBuilder<WalletBloc, WalletState>(
                  builder: (context, state) {
                    if (state is WalletLoaded) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => context.push('/wallet'),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '\$${state.wallet?.balanceUsdc.toStringAsFixed(2) ?? "0.00"} USDC',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Spent \$${state.stats?.spentToday?.toStringAsFixed(2) ?? "0.00"} today',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      );
                    }
                    return const ShimmerPlaceholder(width: 100, height: 40, borderRadius: 20);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── MORNING BRIEFING BANNER (Conditional) ───
          BlocBuilder<BriefingBloc, BriefingState>(
            builder: (context, state) {
              if (state is BriefingLoaded && state.todayBriefing != null && !state.todayBriefing!.isRead) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Dismissible(
                    key: Key(state.todayBriefing!.briefingId),
                    onDismissed: (_) {
                       context.read<BriefingBloc>().add(MarkBriefingRead(state.todayBriefing!.briefingId));
                    },
                    child: InkWell(
                      onTap: () => context.push('/briefing'),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.purple, Colors.teal],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Text('☀️', style: TextStyle(fontSize: 32)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Morning Briefing',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  Text(
                                    '${state.todayBriefing!.totalFindings} findings, \$${state.todayBriefing!.totalCostUsdc.toStringAsFixed(2)} overnight',
                                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // ─── ACTIVE WATCHERS ───
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Your Watchers', '/watchers'),
          const SizedBox(height: 16),
          BlocBuilder<WatchersBloc, WatchersState>(
            builder: (context, state) {
              if (state is WatchersLoaded) {
                final watchers = state.watchers;
                return SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: watchers.length + 1,
                    itemBuilder: (context, index) {
                      if (index < watchers.length) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: WatcherCard(watcher: watchers[index]),
                        );
                      }
                      return _buildAddButton(context);
                    },
                  ),
                );
              }
              return _buildShimmerGrid();
            },
          ),

          // ─── RECENT FINDINGS ───
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Recent Findings', '/findings'),
          const SizedBox(height: 16),
          BlocBuilder<FindingsBloc, FindingsState>(
            builder: (context, state) {
              if (state is FindingsLoaded) {
                final findings = state.findings;
                if (findings.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No findings yet. Your agents are checking... 👻',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: findings.length.clamp(0, 5),
                    itemBuilder: (context, index) => FindingCard(finding: findings[index]),
                  ),
                );
              }
              return _buildShimmerList();
            },
          ),

          // ─── AGENT ACTIVITY INDICATOR ───
          const SizedBox(height: 40),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulsingDot(),
                const SizedBox(width: 8),
                BlocBuilder<WatchersBloc, WatchersState>(
                  builder: (context, state) {
                    final activeCount = state is WatchersLoaded 
                        ? state.watchers.where((w) => w.status == 'active').length 
                        : 0;
                    return Text(
                      '$activeCount watchers active · Next check in 14 min',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          TextButton(
            onPressed: () => context.go(route),
            child: const Text('See All', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/watchers/create'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surface.withAlpha(100), style: BorderStyle.solid),
        ),
        child: const Icon(Icons.add, size: 32, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: 3,
        itemBuilder: (context, index) => const Padding(
           padding: EdgeInsets.only(right: 16),
           child: ShimmerPlaceholder(width: 180, height: 180, borderRadius: 16),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: List.generate(3, (index) => const Padding(
           padding: EdgeInsets.only(bottom: 12),
           child: ShimmerPlaceholder(width: double.infinity, height: 80, borderRadius: 12),
        )),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
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
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppTheme.secondary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
