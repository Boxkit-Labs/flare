import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/widgets/shimmer_utilities.dart';
import 'package:flare_app/core/widgets/status_indicator.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_bloc.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_state.dart';
import 'package:flare_app/features/watchers/presentation/widgets/watcher_card.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_bloc.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_state.dart';
import 'package:flare_app/features/findings/presentation/widgets/finding_card.dart';
import 'package:flare_app/features/briefing/presentation/bloc/briefing_bloc.dart';
import 'package:flare_app/features/briefing/presentation/bloc/briefing_state.dart';
import 'package:flare_app/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flare_app/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:flare_app/features/home/domain/services/ghost_score_service.dart';
import 'package:flare_app/features/notifications/presentation/widgets/notification_badge_icon.dart';

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
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAtmosphericHeader(context),
          const SizedBox(height: 24),
          _buildBentoStatsGrid(context),
          const SizedBox(height: 32),
          _buildMorningBriefing(context),
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Your Systems', '/watchers'),
          _buildWatchersCarousel(context),
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Intelligence Feed', '/findings'),
          _buildFindingsFeed(context),
          const SizedBox(height: 40),
          _buildStatusFooter(context),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildAtmosphericHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, bottom: 40, left: 24, right: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.05),
            AppTheme.primary.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting().toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary.withValues(alpha: 0.6),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.primaryGradient.createShader(bounds),
                    child: Text(
                      'Flare',
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildHeaderAction(
                    context,
                    Icons.sensors_rounded,
                    '/payment-stream',
                    isLive: true,
                  ),
                  const SizedBox(width: 12),
                  const NotificationBadgeIcon(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(
    BuildContext context,
    IconData icon,
    String route, {
    bool isLive = false,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLive ? Colors.red.withValues(alpha: 0.08) : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLive
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isLive ? Colors.redAccent : AppTheme.secondary,
            ),
            if (isLive) ...[
              const SizedBox(width: 8),
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
          ],
        ),
      ),
    );
  }

  Widget _buildBentoStatsGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [

          Row(
            children: [
              Expanded(flex: 3, child: _buildGhostScoreBento(context)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildSavingsBento(context)),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildActiveAgentsBento(context)),
              const SizedBox(width: 16),
              Expanded(child: _buildWalletBento(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGhostScoreBento(BuildContext context) {
    return BlocBuilder<WatchersBloc, WatchersState>(
      builder: (context, watchersState) {
        return BlocBuilder<FindingsBloc, FindingsState>(
          builder: (context, findingsState) {
            double score = 0;
            String tier = '...';
            Map<String, dynamic>? scoreData;

            if (watchersState is WatchersLoaded &&
                findingsState is FindingsLoaded) {
              final walletState = context.read<WalletBloc>().state;
              double totalSpent = 0;
              if (walletState is WalletLoaded)
                totalSpent = walletState.stats?.totalSpentAllTime ?? 0;

              scoreData = GhostScoreService.calculate(
                findingsState.findings,
                watchersState.watchers,
                totalSpent,
                3,
              );
              score = (scoreData['score'] as num).toDouble();
              tier = scoreData['tier']['name'];
            }

            return _buildBentoCard(
              onTap: scoreData != null
                  ? () => _showFlareScoreDetails(context, scoreData!)
                  : null,
              color: AppTheme.secondary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'FLARE SCORE',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 14,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${score.round()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '%',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tier.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSavingsBento(BuildContext context) {
    return BlocBuilder<WatchersBloc, WatchersState>(
      builder: (context, watchersState) {
        return BlocBuilder<FindingsBloc, FindingsState>(
          builder: (context, findingsState) {
            double saved = 0;
            double spent = 0;

            if (findingsState is FindingsLoaded &&
                watchersState is WatchersLoaded) {
              final walletState = context.read<WalletBloc>().state;
              if (walletState is WalletLoaded)
                spent = walletState.stats?.totalSpentAllTime ?? 0;

              final scoreData = GhostScoreService.calculate(
                findingsState.findings,
                watchersState.watchers,
                spent,
                3,
              );
              saved = (scoreData['stats']['totalSavings'] as num).toDouble();
            }

            return _buildBentoCard(
              onTap: () => _showROIDetails(context, saved, spent),
              color: const Color(0xFF10B981),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ROI',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Icon(
                        Icons.arrow_outward_rounded,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 14,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '\$${saved >= 1000 ? (saved / 1000).toStringAsFixed(1) + 'k' : saved.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const Text(
                    'SAVED',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveAgentsBento(BuildContext context) {
    return BlocBuilder<WatchersBloc, WatchersState>(
      builder: (context, state) {
        int active = 0;
        if (state is WatchersLoaded)
          active = state.watchers.where((w) => w.status == 'active').length;

        return _buildBentoCard(
          onTap: () => context.go('/watchers'),
          color: AppTheme.surface,
          bordered: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AGENTS',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    size: 14,
                  ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$active',
                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusIndicator(
                    status: active > 0 ? 'active' : 'paused',
                    size: 10,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'ACTIVE NOW',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletBento(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        double balance = 0;
        if (state is WalletLoaded) balance = state.wallet?.balanceUsdc ?? 0;

        return _buildBentoCard(
          onTap: () => context.push('/wallet'),
          color: AppTheme.surface,
          bordered: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'BALANCE',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    size: 14,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '\$${balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'USDC',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBentoCard({
    required Widget child,
    required Color color,
    bool bordered = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          border: bordered
              ? Border.all(color: Colors.black.withValues(alpha: 0.05))
              : null,
          boxShadow: color == AppTheme.surface
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }

  Widget _buildMorningBriefing(BuildContext context) {
    return BlocBuilder<BriefingBloc, BriefingState>(
      builder: (context, state) {
        if (state is BriefingLoaded &&
            state.todayBriefing != null &&
            !state.todayBriefing!.isRead) {
          final briefing = state.todayBriefing!;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/briefing'),
                  borderRadius: BorderRadius.circular(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text('🌤️', style: TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Morning Briefing',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                briefing.generatedSummary ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWatchersCarousel(BuildContext context) {
    return BlocBuilder<WatchersBloc, WatchersState>(
      builder: (context, state) {
        if (state is WatchersLoaded) {
          final watchers = state.watchers;
          return SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              itemCount: watchers.length + 1,
              itemBuilder: (context, index) {
                if (index < watchers.length) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: WatcherCard(watcher: watchers[index]),
                  );
                }
                return _buildAddWatcherButton(context);
              },
            ),
          );
        }
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: ShimmerGrid(itemCount: 2),
        );
      },
    );
  }

  Widget _buildAddWatcherButton(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/watchers/create'),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              color: AppTheme.primary,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add Agent',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFindingsFeed(BuildContext context) {
    return BlocBuilder<FindingsBloc, FindingsState>(
      builder: (context, state) {
        if (state is FindingsLoaded) {
          final findings = state.findings;
          if (findings.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: findings
                  .take(4)
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FindingCard(finding: f),
                    ),
                  )
                  .toList(),
            ),
          );
        }
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: ShimmerList(itemCount: 2),
        );
      },
    );
  }

  Widget _buildStatusFooter(BuildContext context) {
    return const Center(child: AgentActivityIndicator());
  }

  Widget _buildSectionHeader(BuildContext context, String title, String route) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 12, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          TextButton(
            onPressed: () => context.go(route),
            child: const Text(
              'SEE ALL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
                letterSpacing: 1.0,
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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
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
              child: const Icon(
                Icons.add_rounded,
                size: 28,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add Watcher',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
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
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
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
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 24,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Try Templates',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveButton(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/payment-stream'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'LIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.red,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(String color) {
    switch (color) {
      case 'purple':
        return Colors.purpleAccent;
      case 'gold':
        return Colors.amber;
      case 'blue':
        return Colors.blueAccent;
      case 'green':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  void _showFlareScoreDetails(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Text(
                  data['tier']['icon'],
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data['score']}% Flare Efficiency',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),
                    Text(
                      'Rank: ${data['tier']['name']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getTierColor(data['tier']['color']),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            ...(data['breakdown'] as Map<String, double>).entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.key.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1.0,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '${(e.value * 100).round()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: e.value,
                        backgroundColor: AppTheme.background,
                        color: _getTierColor(data['tier']['color']),
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Your Flare Score is a composite of find quality, spending efficiency, and agent network coverage.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showROIDetails(
    BuildContext context,
    double totalSaved,
    double totalSpent,
  ) {
    final netGain = totalSaved - totalSpent;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.only(
          top: 12,
          bottom: 40,
          left: 24,
          right: 24,
        ),
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
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'ROI Performance',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Real-time financial analysis of your agent network.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: netGain >= 0
                    ? const Color(0xFF10B981)
                    : Colors.redAccent,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color:
                        (netGain >= 0
                                ? const Color(0xFF10B981)
                                : Colors.redAccent)
                            .withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NET HARVEST VALUE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${netGain.abs().toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        ),
                        Text(
                          netGain >= 0 ? 'Surplus Generated' : 'Pending Return',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      netGain >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            _buildROIMetricItem(
              icon: Icons.rocket_launch_rounded,
              label: 'AGENT ENERGY COST',
              value: '-\$${totalSpent.toStringAsFixed(2)}',
              subtitle: 'Total platform compute spent',
              color: Colors.redAccent,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Divider(height: 1, color: Color(0xFFF3F4F6)),
            ),
            _buildROIMetricItem(
              icon: Icons.savings_rounded,
              label: 'LOCKED VALUE RECOVERED',
              value: '+\$${totalSaved.toStringAsFixed(2)}',
              subtitle: 'Savings found across all watchers',
              color: const Color(0xFF10B981),
            ),

            const SizedBox(height: 48),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Historical values are updated as your agents close findings and verify price drops.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildROIMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: color,
          ),
        ),
      ],
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
            _nextCheckMinutes = 60;
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

        if (state is WatchersLoaded) {
          final activeWatchers = state.watchers
              .where((w) => w.status == 'active')
              .toList();
          if (activeWatchers.isNotEmpty) {
            activeWatchers.sort(
              (a, b) =>
                  a.checkIntervalMinutes.compareTo(b.checkIntervalMinutes),
            );
            final next = (activeWatchers.first.checkIntervalMinutes / 2)
                .floor();
            if (next != _nextCheckMinutes) {
              setState(() {
                _nextCheckMinutes = next < 1 ? 1 : next;
              });
            }
          }
        }
      },
      builder: (context, state) {
        int activeCount = 0;
        if (state is WatchersLoaded) {
          activeCount = state.watchers
              .where((w) => w.status == 'active')
              .length;
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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text('·', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(width: 8),
              Text(
                'Next check in ${_nextCheckMinutes}m',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
