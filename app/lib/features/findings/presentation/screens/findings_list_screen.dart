import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/models/models.dart';
import 'package:flare_app/core/widgets/error_state.dart';
import 'package:flare_app/core/widgets/top_snackbar.dart';
import 'package:flare_app/core/widgets/shimmer_utilities.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_bloc.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_event.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_state.dart';
import 'package:flare_app/features/findings/presentation/widgets/finding_card.dart';
import 'package:intl/intl.dart';
import 'package:flare_app/core/widgets/staggered_reveal.dart';

class FindingsListScreen extends StatefulWidget {
  const FindingsListScreen({super.key});

  @override
  State<FindingsListScreen> createState() => _FindingsListScreenState();
}

class _FindingsListScreenState extends State<FindingsListScreen> {
  String _selectedFilter = 'All';
  final ScrollController _scrollController = ScrollController();

  final List<String> _filters = [
    'All',
    'Unread',
    'Flights',
    'Crypto',
    'News',
    'Products',
    'Jobs'
  ];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<FindingsBloc>().add(LoadFindings(authState.user.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Latest Activity', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.8)),
        automaticallyImplyLeading: false,
        centerTitle: false,
        backgroundColor: AppTheme.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              // TODO: Advanced filters
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocListener<FindingsBloc, FindingsState>(
        listener: (context, state) {
          if (state is FindingsError && context.read<FindingsBloc>().state is FindingsLoaded) {
            TopSnackbar.showError(context, state.message);
          }
        },
        child: BlocBuilder<FindingsBloc, FindingsState>(
          builder: (context, state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildFindingsContent(context, state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFindingsContent(BuildContext context, FindingsState state) {
    if (state is FindingsLoaded) {
      final filteredFindings = _applyFilter(state.findings);
      
      if (filteredFindings.isEmpty) {
        return _buildEmptyState();
      }

      final grouped = _groupFindingsByDate(filteredFindings);

      return RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          _refresh();
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: Column(
          key: const ValueKey('loaded'),
          children: [
            _buildFilterChips(state.unreadCount),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: grouped.keys.length,
                itemBuilder: (context, index) {
                  final dateLabel = grouped.keys.elementAt(index);
                  final items = grouped[dateLabel]!;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: Text(
                          dateLabel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: items.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final finding = entry.value;
                            return StaggeredReveal(
                              index: idx,
                              child: FindingCard(finding: finding),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    if (state is FindingsError) {
      return ErrorState(
        key: const ValueKey('error'),
        message: state.message,
        onRetry: _refresh,
      );
    }

    return Column(
      key: const ValueKey('loading'),
      children: [
        const ShimmerGrid(itemCount: 5, itemHeight: 40, padding: EdgeInsets.all(16)),
        Expanded(
          child: ShimmerList(
            itemCount: 8,
            itemHeight: 140,
            padding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(int unreadCount) {
    return Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(filter),
                  if (filter == 'Unread' && unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: TextStyle(
                          fontSize: 10, 
                          color: isSelected ? AppTheme.primary : Colors.white, 
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedFilter = filter),
              backgroundColor: AppTheme.surface,
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
              showCheckmark: false,
              elevation: 0,
              pressElevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected ? AppTheme.primary : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<FindingModel> _applyFilter(List<FindingModel> findings) {
    if (_selectedFilter == 'All') return findings;
    if (_selectedFilter == 'Unread') return findings.where((f) => !f.isRead).toList();
    
    final typeMap = {
      'Flights': 'flight',
      'Crypto': 'crypto',
      'News': 'news',
      'Products': 'product',
      'Jobs': 'job',
    };
    
    final targetType = typeMap[_selectedFilter] ?? _selectedFilter.toLowerCase();
    return findings.where((f) => f.type.toLowerCase() == targetType).toList();
  }

  Map<String, List<FindingModel>> _groupFindingsByDate(List<FindingModel> findings) {
    final Map<String, List<FindingModel>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    for (var finding in findings) {
      final date = DateTime.parse(finding.foundAt);
      final compareDate = DateTime(date.year, date.month, date.day);
      
      String label;
      if (compareDate == today) {
        label = 'Today';
      } else if (compareDate == yesterday) {
        label = 'Yesterday';
      } else if (compareDate.isAfter(weekAgo)) {
        label = 'Earlier this week';
      } else {
        label = DateFormat('MMMM d').format(date);
      }

      if (!groups.containsKey(label)) {
        groups[label] = [];
      }
      groups[label]!.add(finding);
    }
    return groups;
  }

  Widget _buildEmptyState() {
     return SingleChildScrollView(
       key: const ValueKey('empty'),
       physics: const AlwaysScrollableScrollPhysics(),
       child: Container(
         height: MediaQuery.of(context).size.height * 0.6,
         alignment: Alignment.center,
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
               child: const Text('💎', style: TextStyle(fontSize: 48)),
             ),
             const SizedBox(height: 24),
             const Text(
               'No discoveries found',
               style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
             ),
             const SizedBox(height: 12),
             const Padding(
               padding: EdgeInsets.symmetric(horizontal: 48),
               child: Text(
                 'Your agents are still scanning for matches. Increase your budget or refine your criteria to find results faster.',
                 textAlign: TextAlign.center,
                 style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
               ),
             ),
             const SizedBox(height: 32),
             ElevatedButton(
               onPressed: () => context.push('/watchers/create'),
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.black,
                 foregroundColor: Colors.white,
                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               ),
               child: const Text('Deploy Agent', style: TextStyle(fontWeight: FontWeight.bold)),
             ),
           ],
         ),
       ),
     );
  }
}

