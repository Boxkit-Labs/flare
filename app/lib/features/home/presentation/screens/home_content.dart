import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/widgets/shimmer_utilities.dart';
import 'package:flare_app/core/widgets/status_indicator.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_bloc.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_event.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_state.dart';
import 'package:flare_app/features/watchers/presentation/widgets/watcher_card.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_bloc.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_event.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_state.dart';
import 'package:flare_app/features/findings/presentation/widgets/finding_card.dart';
import 'package:flare_app/features/briefing/presentation/bloc/briefing_bloc.dart';
import 'package:flare_app/features/briefing/presentation/bloc/briefing_state.dart';
import 'package:flare_app/features/briefing/presentation/bloc/briefing_event.dart';
import 'package:flare_app/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flare_app/features/wallet/presentation/bloc/wallet_event.dart';
import 'package:flare_app/features/wallet/presentation/bloc/wallet_state.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _onRetry(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final userId = authState.user.userId;
      context.read<WalletBloc>().add(LoadAllWalletData(userId));
      context.read<WatchersBloc>().add(LoadWatchers(userId));
      context.read<FindingsBloc>().add(LoadFindings(userId));
      context.read<BriefingBloc>().add(LoadTodayBriefing(userId));
    }
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ready to hunt',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                BlocBuilder<WalletBloc, WalletState>(
                  builder: (context, state) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildWalletCapsule(context, state),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ─── MORNING BRIEFING BANNER ───
          BlocBuilder<BriefingBloc, BriefingState>(
            builder: (context, state) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _buildBriefingBanner(context, state),
              );
            },
          ),

          // ─── ACTIVE WATCHERS ───
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Your Watchers', '/watchers'),
          const SizedBox(height: 20),
          BlocBuilder<WatchersBloc, WatchersState>(
            builder: (context, state) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _buildWatchersSection(context, state),
              );
            },
          ),

          // ─── RECENT FINDINGS ───
          const SizedBox(height: 48),
          _buildSectionHeader(context, 'Recent Findings', '/findings'),
          const SizedBox(height: 20),
          BlocBuilder<FindingsBloc, FindingsState>(
            builder: (context, state) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _buildFindingsSection(context, state),
              );
            },
          ),

          // ─── AGENT ACTIVITY INDICATOR ───
          const SizedBox(height: 60),
          const Center(child: AgentActivityIndicator()),
          const SizedBox(height: 100), // Extra space for the floating-effect navbar
        ],
      ),
    );
  }

  Widget _buildWalletCapsule(BuildContext context, WalletState state) {
    if (state is WalletLoaded) {
      final balance = state.wallet?.balanceUsdc ?? 0.0;
      return InkWell(
        onTap: () => context.push('/wallet'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            boxShadow: [
               BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet_rounded, size: 14, color: AppTheme.primary),
              const SizedBox(width: 8),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: balance),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Text(
                    '\$${value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }
    if (state is WalletError) {
      return IconButton(
        icon: const Icon(Icons.refresh_rounded, color: AppTheme.error),
        onPressed: () => _onRetry(context),
      );
    }
    return const ShimmerPlaceholder(
      width: 80,
      height: 36,
      borderRadius: 18,
    );
  }

  Widget _buildBriefingBanner(BuildContext context, BriefingState state) {
    if (state is BriefingLoaded && state.todayBriefing != null && !state.todayBriefing!.isRead) {
      final briefing = state.todayBriefing!;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Dismissible(
            key: Key(briefing.briefingId),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
               context.read<BriefingBloc>().add(MarkBriefingRead(briefing.briefingId));
            },
            child: InkWell(
              onTap: () => context.push('/briefing'),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(child: Text('☀️', style: TextStyle(fontSize: 28))),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Morning Briefing',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${briefing.totalFindings} findings · \$${briefing.totalCostUsdc.toStringAsFixed(2)} overnight',
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.5), size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildWatchersSection(BuildContext context, WatchersState state) {
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
            return Row(
              children: [
                _buildAddButton(context),
                _buildTemplatesButton(context),
              ],
            );
          },
        ),
      );
    }
    if (state is WatchersError) {
      return Center(
        child: TextButton.icon(
          onPressed: () => _onRetry(context),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      );
    }
    return const ShimmerGrid(itemCount: 3);
  }

  Widget _buildFindingsSection(BuildContext context, FindingsState state) {
    if (state is FindingsLoaded) {
      final findings = state.findings;
      if (findings.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              Text('👻', style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text(
                'No findings yet. Your agents are hunting...',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: findings.length.clamp(0, 5),
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FindingCard(finding: findings[index]),
          ),
        ),
      );
    }
    if (state is FindingsError) {
      return Center(
        child: TextButton.icon(
          onPressed: () => _onRetry(context),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      );
    }
    return const ShimmerList(itemCount: 3);
  }

  Widget _buildSectionHeader(BuildContext context, String title, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
          ),
          InkWell(
            onTap: () => context.go(route),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: const Row(
                children: [
                  Text('See All', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 13)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: AppTheme.primary, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/watchers/create'),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
             BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, size: 28, color: AppTheme.primary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add Watcher',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesButton(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/watchers/templates'),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
          boxShadow: [
             BoxShadow(color: AppTheme.primary.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 24, color: AppTheme.primary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Try Templates',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class AgentActivityIndicator extends StatefulWidget {
  const AgentActivityIndicator({super.key});

  @override
  State<AgentActivityIndicator> createState() => _AgentActivityIndicatorState();
}

class _AgentActivityIndicatorState extends State<AgentActivityIndicator> {
  Timer? _timer;
  int _nextCheckMinutes = 14;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_nextCheckMinutes > 1) {
            _nextCheckMinutes--;
          } else {
            _nextCheckMinutes = 60; // Simple loop until re-synced by bloc
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WatchersBloc, WatchersState>(
      listener: (context, state) {
        // Sync actual next check minutes from network data
        if (state is WatchersLoaded) {
           final activeWatchers = state.watchers.where((w) => w.status == 'active').toList();
           if (activeWatchers.isNotEmpty) {
             activeWatchers.sort((a, b) => a.checkIntervalMinutes.compareTo(b.checkIntervalMinutes));
             setState(() {
               _nextCheckMinutes = (activeWatchers.first.checkIntervalMinutes / 2).floor();
               if (_nextCheckMinutes < 1) _nextCheckMinutes = 1;
             });
           }
        }
      },
      builder: (context, state) {
        int activeCount = 0;
        if (state is WatchersLoaded) {
          activeCount = state.watchers.where((w) => w.status == 'active').length;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusIndicator(status: activeCount > 0 ? 'active' : 'paused'),
              const SizedBox(width: 12),
              Text(
                '$activeCount Agents Active',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 8),
              const Text('·', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(width: 8),
              Text(
                'Next check in ${_nextCheckMinutes}m',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}

