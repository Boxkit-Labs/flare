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
      context.read<BriefingBloc>().add(LoadBriefingHistory(userId, limit: 7));
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BriefingBloc, BriefingState>(
      listener: (context, state) {
        if (state is BriefingGenerated) {
          TopSnackbar.showSuccess(context, '⚡ Your digest is ready!');
          _refresh();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _changeDate(-1), 
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d').format(_selectedDate), 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.5),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _selectedDate.day == DateTime.now().day ? null : () => _changeDate(1), 
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: BlocBuilder<BriefingBloc, BriefingState>(
          builder: (context, state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildBriefingBody(context, state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBriefingBody(BuildContext context, BriefingState state) {
    if (state is BriefingLoaded) {
      final briefing = state.todayBriefing; 
      
      if (briefing == null && _selectedDate.day == DateTime.now().day) {
        return _buildNoBriefingState();
      }

      if (briefing != null) {
        return RefreshIndicator(
          key: ValueKey('briefing_${briefing.briefingId}'),
          color: AppTheme.primary,
          onRefresh: () async {
            _refresh();
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: _buildBriefingContent(briefing),
        );
      }
    }

    if (state is BriefingError) {
      return ErrorState(
        key: const ValueKey('error'),
        message: state.message,
        onRetry: _refresh,
      );
    }

    return SingleChildScrollView(
      key: const ValueKey('loading'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerPlaceholder(width: 200, height: 32),
          const SizedBox(height: 12),
          const ShimmerPlaceholder(width: 250, height: 16),
          const SizedBox(height: 48),
          const ShimmerHeader(),
          const SizedBox(height: 20),
          const ShimmerList(itemCount: 2, itemHeight: 140, padding: EdgeInsets.zero),
          const SizedBox(height: 40),
          const ShimmerHeader(),
          const SizedBox(height: 20),
          const ShimmerList(itemCount: 3, itemHeight: 80, padding: EdgeInsets.zero),
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
                 boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20),
                 ],
               ),
               child: const Text('☕', style: TextStyle(fontSize: 48)),
             ),
             const SizedBox(height: 24),
             const Text('Daily Digest', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
             const SizedBox(height: 12),
             const Text(
               'Ready for your morning update? Your agents have been working overnight. Generate your briefing to see what they found.', 
               textAlign: TextAlign.center, 
               style: TextStyle(color: AppTheme.textSecondary, height: 1.5, fontSize: 15),
             ),
             const SizedBox(height: 40),
             Container(
               width: double.infinity,
               decoration: BoxDecoration(
                 gradient: AppTheme.primaryGradient,
                 borderRadius: BorderRadius.circular(16),
                 boxShadow: [
                   BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                 ],
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
                 child: const Text('Generate Digest', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
               ),
             ),
           ],
         ),
       ),
     );
  }

  Widget _buildBriefingContent(BriefingModel briefing) {
     final findings = briefing.findingsJson.map((f) => FindingModel.fromJson(f as Map<String, dynamic>)).toList();
     final summaries = briefing.watcherSummaries;

     return ListView(
       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
       physics: const BouncingScrollPhysics(),
       children: [
         Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(
               DateFormat('EEEE, MMMM d').format(DateTime.parse(briefing.date)), 
               style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1.0),
             ),
             const SizedBox(height: 12),
             Row(
               children: [
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                   child: Text(
                     '${briefing.totalChecks} AGENT CHECKS', 
                     style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                   ),
                 ),
                 const SizedBox(width: 8),
                 Text(
                   'Completed overnight', 
                   style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
                 ),
               ],
             ),
             const SizedBox(height: 48),
           ],
         ),
         
         if (findings.isNotEmpty) ...[
           _buildSectionHeader('⚡ Signal Detected', count: findings.length),
           const SizedBox(height: 20),
           ...findings.asMap().entries.map((entry) {
             return StaggeredReveal(
               index: entry.key,
               child: FindingCard(finding: entry.value),
             );
           }),
           const SizedBox(height: 40),
         ],

         _buildSectionHeader('📊 Agent Status'),
         const SizedBox(height: 20),
         ...summaries.asMap().entries.map((entry) {
           return StaggeredReveal(
             index: entry.key + findings.length,
             child: _buildNoChangeTile(entry.value),
           );
         }),

         const SizedBox(height: 48),
         _buildCostSummary(briefing),
         const SizedBox(height: 100),
       ],
     );
  }

  Widget _buildSectionHeader(String title, {int? count}) {
     return Row(
       children: [
         Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
         if (count != null) ...[
           const SizedBox(width: 12),
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
             decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
             child: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
           ),
         ],
       ],
     );
  }

  Widget _buildNoChangeTile(WatcherSummary summary) {
     final emoji = _getEmoji(summary.type);
     final name = summary.watcherName;
     final latestData = summary.latestDataSummary.isNotEmpty ? summary.latestDataSummary : 'Nominal activity detected.';

     return Container(
       margin: const EdgeInsets.only(bottom: 12),
       decoration: BoxDecoration(
         color: AppTheme.surface,
         borderRadius: BorderRadius.circular(20),
         boxShadow: [
           BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
         ],
         border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
       ),
       child: Theme(
         data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
         child: ExpansionTile(
           leading: Container(
             width: 40,
             height: 40,
             decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
             child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
           ),
           title: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
           subtitle: Text(
             latestData, 
             style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
             maxLines: 1,
             overflow: TextOverflow.ellipsis,
           ),
           iconColor: AppTheme.primary,
           collapsedIconColor: AppTheme.textSecondary,
           children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    summary.latestDataSummary.isNotEmpty 
                       ? summary.latestDataSummary 
                       : 'Your agent scanned ${summary.type} and found no items meeting your priority thresholds. Next scan scheduled in 4 hours. 👻',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
           ],
         ),
       ),
     );
  }

  Widget _buildCostSummary(BriefingModel briefing) {
     final avgCost = briefing.totalFindings > 0 
        ? briefing.totalCostUsdc / briefing.totalFindings 
        : 0.0;

     return Container(
       padding: const EdgeInsets.all(24),
       decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(28),
       ),
       child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Digest Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
            const SizedBox(height: 24),
            _buildSummaryRow('Operation Cost', '\$${briefing.totalCostUsdc.toStringAsFixed(3)} USDC', isDark: true),
            const SizedBox(height: 12),
            _buildSummaryRow('Efficiency', 'Found ${briefing.totalFindings} signals from ${briefing.totalChecks} scans', isDark: true),
            const SizedBox(height: 12),
            _buildSummaryRow('Avg Signal Cost', '\$${avgCost.toStringAsFixed(3)}', isDark: true),
            const Divider(height: 48, color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                  child: const Text('\$4.82 USDC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                ),
              ],
            ),
          ],
       ),
     );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDark = false}) {
     return Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         Text(label, style: TextStyle(color: isDark ? Colors.white60 : AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
         Text(value, style: TextStyle(color: isDark ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 13)),
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
      default: return '✨';
    }
  }
}
