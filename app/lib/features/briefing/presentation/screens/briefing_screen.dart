import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/models/models.dart';
import 'package:flare_app/core/widgets/error_state.dart';
import 'package:flare_app/core/widgets/shimmer_utilities.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flare_app/features/briefing/presentation/bloc/briefing_bloc.dart';
import 'package:flare_app/features/briefing/presentation/bloc/briefing_event.dart';
import 'package:flare_app/features/briefing/presentation/bloc/briefing_state.dart';
import 'package:flare_app/features/briefing/presentation/widgets/horizontal_calendar.dart';
import 'package:flare_app/features/findings/presentation/widgets/finding_card.dart';
import 'package:intl/intl.dart';
import 'package:flare_app/core/widgets/staggered_reveal.dart';
import 'package:flare_app/core/widgets/top_snackbar.dart';

class BriefingScreen extends StatefulWidget {
  const BriefingScreen({super.key});

  @override
  State<BriefingScreen> createState() => _BriefingScreenState();
}

class _BriefingScreenState extends State<BriefingScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _refresh();
  }

  void _refresh() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final userId = authState.user.userId;
      context.read<BriefingBloc>().add(LoadTodayBriefing(userId));
      context.read<BriefingBloc>().add(LoadBriefingHistory(userId, limit: 14));
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<BriefingBloc>().add(LoadBriefingByDate(authState.user.userId, date));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BriefingBloc, BriefingState>(
      listener: (context, state) {
        if (state is BriefingGenerated) {
          TopSnackbar.showSuccess(context, '⚡ Your Flare Digest is ready!');
          _refresh();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              HorizontalCalendar(
                selectedDate: _selectedDate,
                onDateSelected: _onDateSelected,
              ),
              Expanded(
                child: BlocBuilder<BriefingBloc, BriefingState>(
                  builder: (context, state) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _buildBriefingBody(context, state),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Flare Digest',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Intelligence for your day',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBriefingBody(BuildContext context, BriefingState state) {
    final dateKey = _selectedDate.toIso8601String().split('T')[0];

    if (state is BriefingLoading && _isSelectingNewDate(state, dateKey)) {
      return _buildLoadingState();
    }

    if (state is BriefingLoaded || state is BriefingGenerating) {
      final isToday = dateKey == DateTime.now().toIso8601String().split('T')[0];

      BriefingModel? briefing;
      if (state is BriefingLoaded) {
        if (isToday) {
          briefing = state.todayBriefing;
        } else {
          briefing = state.briefingsByDate[dateKey];
        }
      }

      if (briefing == null) {
        if (isToday && state is! BriefingGenerating) {
          return _buildNoBriefingState();
        } else if (state is BriefingGenerating) {
            return _buildGeneratingState();
        } else {
          return _buildNoBriefingHistoricalState();
        }
      }

      return RefreshIndicator(
        key: ValueKey('briefing_$dateKey'),
        color: AppTheme.primary,
        onRefresh: () async {
          _refresh();
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: _buildBriefingContent(briefing),
      );
    }

    if (state is BriefingError) {
      return ErrorState(
        key: const ValueKey('error'),
        message: state.message,
        onRetry: _refresh,
      );
    }

    return _buildLoadingState();
  }

  bool _isSelectingNewDate(BriefingState state, String currentKey) {
    if (state is BriefingLoaded) {

      final isToday = currentKey == DateTime.now().toIso8601String().split('T')[0];
      if (!isToday && !state.briefingsByDate.containsKey(currentKey)) {
          return true;
      }
    }
    return state is BriefingLoading;
  }

  Widget _buildLoadingState() {
     return SingleChildScrollView(
      key: const ValueKey('loading'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerPlaceholder(width: 220, height: 32),
          const SizedBox(height: 12),
          const ShimmerPlaceholder(width: 140, height: 16),
          const SizedBox(height: 40),
          const ShimmerHeader(),
          const SizedBox(height: 20),
          const ShimmerList(itemCount: 2, itemHeight: 140, padding: EdgeInsets.zero),
        ],
      ),
    );
  }

  Widget _buildGeneratingState() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 24),
            const Text(
              'Assembling Intel...',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Your agents are compiling their findings.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
  }

  Widget _buildNoBriefingState() {
     return Center(
       child: Padding(
         padding: const EdgeInsets.symmetric(horizontal: 40),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Container(
               padding: const EdgeInsets.all(32),
               decoration: BoxDecoration(
                 color: AppTheme.surface,
                 shape: BoxShape.circle,
               ),
               child: const Text('💡', style: TextStyle(fontSize: 48)),
             ),
             const SizedBox(height: 24),
             const Text('Daily Digest', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
             const SizedBox(height: 12),
             const Text(
               'Ready for your briefing? Your agents have been active. Generate your intel report now.',
               textAlign: TextAlign.center,
               style: TextStyle(color: AppTheme.textSecondary, height: 1.5, fontSize: 15),
             ),
             const SizedBox(height: 40),
             Container(
               width: double.infinity,
               decoration: BoxDecoration(
                 gradient: AppTheme.primaryGradient,
                 borderRadius: BorderRadius.circular(16),
               ),
               child: ElevatedButton(
                 onPressed: () {
                   final authState = context.read<AuthBloc>().state;
                   if (authState is AuthAuthenticated) {
                     context.read<BriefingBloc>().add(GenerateManualBriefing(authState.user.userId));
                   }
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.transparent,
                   shadowColor: Colors.transparent,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 ),
                 child: const Text('Generate Intelligence', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
               ),
             ),
           ],
         ),
       ),
     );
  }

  Widget _buildNoBriefingHistoricalState() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(opacity: 0.3, child: const Icon(Icons.history_rounded, size: 64)),
            const SizedBox(height: 16),
            const Text('No Archives Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('There was no activity tracked on this date.', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
  }

  Widget _buildBriefingContent(BriefingModel briefing) {
     final findings = briefing.findingsJson.map((f) => FindingModel.fromJson(f as Map<String, dynamic>)).toList();
     final summaries = briefing.watcherSummaries;

     return ListView(
       padding: const EdgeInsets.all(20),
       physics: const BouncingScrollPhysics(),
       children: [
         Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(
               DateFormat('EEEE, MMM d').format(DateTime.parse(briefing.date)),
               style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1.0),
             ),
             const SizedBox(height: 12),
             Row(
               children: [
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                   decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                   child: Text(
                     '${briefing.totalChecks} AGENT SCANS',
                     style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                   ),
                 ),
                 const SizedBox(width: 12),
                 Text(
                   'Status: Optimized',
                   style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w700),
                 ),
               ],
             ),
             const SizedBox(height: 32),
           ],
         ),

         if (findings.isNotEmpty) ...[
           _buildSectionHeader('Intelligence Findings', count: findings.length),
           const SizedBox(height: 16),
           ...findings.asMap().entries.map((entry) {
             return StaggeredReveal(
               index: entry.key,
               child: FindingCard(finding: entry.value),
             );
           }),
           const SizedBox(height: 32),
         ],

         _buildSectionHeader('Agent Reconnaissance'),
         const SizedBox(height: 16),
         ...summaries.asMap().entries.map((entry) {
           return StaggeredReveal(
             index: entry.key + findings.length,
             child: _buildAgentSummaryTile(entry.value),
           );
         }),

         const SizedBox(height: 48),
         _buildDigestFooter(briefing),
         const SizedBox(height: 80),
       ],
     );
  }

  Widget _buildSectionHeader(String title, {int? count}) {
      return Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ),
          ],
        ],
      );
  }

  Widget _buildAgentSummaryTile(WatcherSummary summary) {
      final emoji = _getEmoji(summary.type);
      final latestData = summary.latestDataSummary.isNotEmpty ? summary.latestDataSummary : 'No critical changes found.';

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
            ),
            title: Text(summary.watcherName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            subtitle: Text(
              latestData,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            children: [
               Padding(
                 padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                 child: Text(
                   summary.latestDataSummary.isNotEmpty
                      ? summary.latestDataSummary
                      : 'Your agent scanned ${summary.type} and verified all nodes were stable. Flare Score remains constant.',
                   style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                 ),
               ),
            ],
          ),
        ),
      );
  }

  Widget _buildDigestFooter(BriefingModel briefing) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
           color: Colors.black,
           borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text('Flare Score', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                 Text('${Math.min(100, (briefing.totalFindings * 25) + 45)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 24)),
               ],
             ),
             const SizedBox(height: 24),
             _buildSummaryRow('Operational Cost', '\$${briefing.totalCostUsdc.toStringAsFixed(3)} USDC', true),
             const SizedBox(height: 12),
             _buildSummaryRow('Scanned Agents', '${summariesCount(briefing)}', true),
             const Divider(height: 40, color: Colors.white12),
             const Text('Intelligence efficiency: High', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w700)),
           ],
        ),
      );
  }

  int summariesCount(BriefingModel b) => b.watcherSummaries.length;

  Widget _buildSummaryRow(String label, String value, bool isDark) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white60 : AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: isDark ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      );
  }

  String _getEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'flight':
      case 'flights': return '✈️';
      case 'crypto': return '💰';
      case 'news': return '📰';
      case 'product':
      case 'products': return '🛍️';
      case 'job':
      case 'jobs': return '💼';
      case 'stock': return '📈';
      case 'realestate': return '🏠';
      case 'sports': return '🏆';
      default: return '✨';
    }
  }
}

class Math {
   static num min(num a, num b) => a < b ? a : b;
}
