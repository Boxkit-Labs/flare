import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/widgets/error_state.dart';
import 'package:flare_app/core/widgets/top_snackbar.dart';
import 'package:flare_app/core/widgets/shimmer_utilities.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_bloc.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_event.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_state.dart';
import 'package:flare_app/features/watchers/presentation/widgets/watcher_list_tile.dart';

class WatchersListScreen extends StatefulWidget {
  const WatchersListScreen({super.key});

  @override
  State<WatchersListScreen> createState() => _WatchersListScreenState();
}

class _WatchersListScreenState extends State<WatchersListScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All', 'Active', 'Paused', 'Flights', 'Crypto', 'News', 'Products', 'Jobs'
  ];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<WatchersBloc>().add(LoadWatchers(authState.user.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Your Watchers', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.8)),
        automaticallyImplyLeading: false,
        centerTitle: false,
        backgroundColor: AppTheme.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: () {

            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocListener<WatchersBloc, WatchersState>(
        listener: (context, state) {
          if (state is WatcherActionSuccess) {
            TopSnackbar.showSuccess(context, state.message);
          } else if (state is WatchersError && context.read<WatchersBloc>().state is WatchersLoaded) {

            TopSnackbar.showError(context, state.message);
          }
        },
        child: Column(
          children: [
            _buildFilterChips(),
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () async {
                  _refresh();
                  await Future.delayed(const Duration(milliseconds: 800));
                },
                child: BlocBuilder<WatchersBloc, WatchersState>(
                  builder: (context, state) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildWatcherListContent(context, state),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => context.push('/watchers/create'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        label: const Text('New Watcher', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildWatcherListContent(BuildContext context, WatchersState state) {
    if (state is WatchersLoaded) {
      final filteredWatchers = _applyFilter(state.watchers);

      if (filteredWatchers.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        key: const ValueKey('loaded'),
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        physics: const BouncingScrollPhysics(),
        itemCount: filteredWatchers.length,
        itemBuilder: (context, index) {
           final watcher = filteredWatchers[index];
           return WatcherListTile(
             watcher: watcher,
             onToggle: (isActive) {
               context.read<WatchersBloc>().add(ToggleWatcher(watcher.watcherId));
             },
             onDelete: () {
               context.read<WatchersBloc>().add(DeleteWatcher(watcher.watcherId));
             },
             onEdit: () => context.push('/watchers/${watcher.watcherId}/edit'),
           );
        },
      );
    }

    if (state is WatchersError) {
      return ErrorState(
        key: const ValueKey('error'),
        message: state.message,
        onRetry: _refresh,
      );
    }

    return ShimmerList(
      key: const ValueKey('loading'),
      itemCount: 6,
      itemHeight: 120,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildFilterChips() {
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
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilter = filter);
              },
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
               child: const Text('🔭', style: TextStyle(fontSize: 48)),
             ),
             const SizedBox(height: 24),
             const Text(
               'No active watchers',
               style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
             ),
             const SizedBox(height: 12),
             const Padding(
               padding: EdgeInsets.symmetric(horizontal: 48),
               child: Text(
                 'Deploy an agent to monitor prices, news, or jobs for you.',
                 textAlign: TextAlign.center,
                 style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
               ),
             ),
             const SizedBox(height: 32),
             _buildFab(),
           ],
         ),
       ),
     );
  }

  List<dynamic> _applyFilter(List<dynamic> watchers) {
    if (_selectedFilter == 'All') return watchers;
    if (_selectedFilter == 'Active') return watchers.where((w) => w.status == 'active').toList();
    if (_selectedFilter == 'Paused') return watchers.where((w) => w.status == 'paused').toList();

    final typeMap = {
      'Flights': 'flight',
      'Crypto': 'crypto',
      'News': 'news',
      'Products': 'product',
      'Jobs': 'job',
    };

    final targetType = typeMap[_selectedFilter] ?? _selectedFilter.toLowerCase();
    return watchers.where((w) => w.type.toLowerCase() == targetType).toList();
  }
}

