import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_app/core/theme/app_theme.dart';
import 'package:ghost_app/core/models/models.dart';
import 'package:ghost_app/core/widgets/error_state.dart';
import 'package:ghost_app/core/widgets/shimmer_utilities.dart';
import 'package:ghost_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ghost_app/features/findings/presentation/bloc/findings_bloc.dart';
import 'package:ghost_app/features/findings/presentation/bloc/findings_event.dart';
import 'package:ghost_app/features/findings/presentation/bloc/findings_state.dart';
import 'package:ghost_app/features/findings/presentation/widgets/finding_card.dart';
import 'package:intl/intl.dart';
import 'package:ghost_app/core/widgets/staggered_reveal.dart';

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
    try {
      final userId = (authState as dynamic).user.userId;
      context.read<FindingsBloc>().add(LoadFindings(userId));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Findings', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Advanced filters
            },
          ),
        ],
      ),
      body: BlocBuilder<FindingsBloc, FindingsState>(
        builder: (context, state) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _buildFindingsContent(context, state),
          );
        },
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: grouped.keys.length,
                itemBuilder: (context, index) {
                  final dateLabel = grouped.keys.elementAt(index);
                  final items = grouped[dateLabel]!;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          dateLabel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final finding = entry.value;
                        return StaggeredReveal(
                          index: idx,
                          child: FindingCard(finding: finding),
                        );
                      }),
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
            itemHeight: 120,
            padding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(int unreadCount) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(filter),
                  if (filter == 'Unread' && unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedFilter = filter),
              backgroundColor: AppTheme.surface,
              selectedColor: AppTheme.primary.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? AppTheme.primary : Colors.transparent),
            ),
          );
        },
      ),
    );
  }

  List<FindingModel> _applyFilter(List<FindingModel> findings) {
    if (_selectedFilter == 'All') return findings;
    if (_selectedFilter == 'Unread') return findings.where((f) => !f.isRead).toList();
    return findings.where((f) => f.type.toLowerCase() == _selectedFilter.toLowerCase()).toList();
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👻', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'No findings yet.\nYour agents are working on it.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.goNamed('createWatcher'),
            child: const Text('Deploy an Agent'),
          ),
        ],
      ),
    );
  }
}
