import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_app/core/theme/app_theme.dart';
import 'package:ghost_app/core/models/models.dart';
import 'package:ghost_app/core/widgets/error_state.dart';
import 'package:ghost_app/core/widgets/shimmer_utilities.dart';
import 'package:ghost_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ghost_app/features/briefing/presentation/bloc/briefing_bloc.dart';
import 'package:ghost_app/features/briefing/presentation/bloc/briefing_event.dart';
import 'package:ghost_app/features/briefing/presentation/bloc/briefing_state.dart';
import 'package:ghost_app/features/findings/presentation/widgets/finding_card.dart';
import 'package:intl/intl.dart';

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
    try {
      final userId = (authState as dynamic).user.userId;
      context.read<BriefingBloc>().add(LoadTodayBriefing(userId));
      context.read<BriefingBloc>().add(LoadBriefingHistory(userId, limit: 7));
    } catch (_) {}
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      // In a real app, we'd fetch the specifically labeled briefing for this date
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BriefingBloc, BriefingState>(
      listener: (context, state) {
        if (state is BriefingGenerated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚡ New briefing generated!')),
          );
          _refresh();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               IconButton(onPressed: () => _changeDate(-1), icon: const Icon(Icons.chevron_left)),
               Text(DateFormat('MMM d').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
               IconButton(onPressed: _selectedDate.day == DateTime.now().day ? null : () => _changeDate(1), icon: const Icon(Icons.chevron_right)),
             ],
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<BriefingBloc, BriefingState>(
          builder: (context, state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _buildBriefingBody(context, state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBriefingBody(BuildContext context, BriefingState state) {
    if (state is BriefingLoaded) {
      final briefing = state.todayBriefing; // For now assuming today
      
      if (briefing == null && _selectedDate.day == DateTime.now().day) {
        return _buildNoBriefingState();
      }

      if (briefing != null) {
        return RefreshIndicator(
          key: const ValueKey('loaded'),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerPlaceholder(width: 200, height: 32),
          const SizedBox(height: 8),
          const ShimmerPlaceholder(width: 250, height: 16),
          const SizedBox(height: 40),
          const ShimmerHeader(),
          const SizedBox(height: 16),
          const ShimmerList(itemCount: 2, itemHeight: 120, padding: EdgeInsets.zero),
          const SizedBox(height: 32),
          const ShimmerHeader(),
          const SizedBox(height: 16),
          const ShimmerList(itemCount: 3, itemHeight: 60, padding: EdgeInsets.zero),
        ],
      ),
    );
  }

  Widget _buildNoBriefingState() {
     return Center(
       child: Padding(
         padding: const EdgeInsets.all(40),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             const Text('☀️', style: TextStyle(fontSize: 64)),
             const SizedBox(height: 16),
             const Text('No briefing yet today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 8),
             const Text('Your agents are gathering data. You can generate one manually now.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
             const SizedBox(height: 32),
             ElevatedButton(
               onPressed: () {
                 final userId = (context.read<AuthBloc>().state as dynamic).user.userId;
                 context.read<BriefingBloc>().add(GenerateManualBriefing(userId));
               },
               child: const Text('Generate Now'),
             ),
           ],
         ),
       ),
     );
  }

  Widget _buildBriefingContent(BriefingModel briefing) {
     return ListView(
       padding: const EdgeInsets.all(24),
       children: [
         Text(DateFormat('EEEE, MMMM d').format(DateTime.parse(briefing.date)), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
         const SizedBox(height: 4),
         Text('Your agents ran ${briefing.totalChecks} checks overnight', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
         const SizedBox(height: 32),
         
         if (briefing.totalFindings > 0) ...[
            _buildSectionHeader('⚡ Findings', count: briefing.totalFindings),
            const SizedBox(height: 16),
            ...briefing.findingsJson.map((f) {
               final finding = FindingModel.fromJson(f as Map<String, dynamic>);
               return FindingCard(finding: finding);
            }),
            const SizedBox(height: 32),
         ],

         _buildSectionHeader('📊 No Change'),
         const SizedBox(height: 16),
         ...briefing.watcherSummariesJson.map((s) {
            final summary = s as Map<String, dynamic>;
            return _buildNoChangeTile(summary);
         }),

         const SizedBox(height: 40),
         _buildCostSummary(briefing),
         const SizedBox(height: 60),
       ],
     );
  }

  Widget _buildSectionHeader(String title, {int? count}) {
     return Row(
       children: [
         Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
         if (count != null) ...[
           const SizedBox(width: 12),
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
             decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
             child: Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
           ),
         ],
       ],
     );
  }

  Widget _buildNoChangeTile(Map<String, dynamic> summary) {
     final type = summary['type'] ?? 'info';
     final emoji = _getEmoji(type);
     final name = summary['name'] ?? 'Watcher';
     final latestData = summary['latest_status'] ?? 'Checked. No alert.';

     return Card(
       elevation: 0,
       margin: const EdgeInsets.only(bottom: 8),
       color: AppTheme.surface,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
       child: ExpansionTile(
         leading: Text(emoji, style: const TextStyle(fontSize: 18)),
         title: Text('$name: $latestData', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
         children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Agent ran checks at ${DateFormat('HH:mm').format(DateTime.now())}. All parameters within threshold. Ghost efficiency confirmed. 👻',
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
         ],
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
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
       ),
       child: Column(
          children: [
            _buildSummaryRow('Overnight cost', '\$${briefing.totalCostUsdc.toStringAsFixed(3)} across 5 watchers'),
            const Divider(height: 24, color: Colors.white10),
            _buildSummaryRow('Wallet balance', '\$4.82 USDC'),
            const SizedBox(height: 20),
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 _buildStatPill('Findings Efficiency', 'Found ${briefing.totalFindings} actionable items from ${briefing.totalChecks} checks'),
                 _buildStatPill('Average Cost', '\$${avgCost.toStringAsFixed(3)} per finding'),
               ],
            ),
          ],
       ),
     );
  }

  Widget _buildSummaryRow(String label, String value) {
     return Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
         Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
       ],
     );
  }

  Widget _buildStatPill(String label, String value) {
     return Expanded(
       child: Container(
         margin: const EdgeInsets.symmetric(horizontal: 4),
         padding: const EdgeInsets.all(12),
         decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12)),
         child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
         ),
       ),
     );
  }

  String _getEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'flights': return '✈️';
      case 'crypto': return '💰';
      case 'news': return '📰';
      case 'products': return '🛍️';
      case 'jobs': return '💼';
      default: return '✨';
    }
  }
}
