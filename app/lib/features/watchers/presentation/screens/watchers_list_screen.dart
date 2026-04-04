import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/widgets/error_state.dart';
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
      appBar: AppBar(
        title: const Text('Watchers', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // TODO: Implement sorting dialog
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _refresh();
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: BlocBuilder<WatchersBloc, WatchersState>(
                builder: (context, state) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: _buildWatcherListContent(context, state),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/watchers/create'),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWatcherListContent(BuildContext context, WatchersState state) {
    if (state is WatchersLoaded) {
      final filteredWatchers = _applyFilter(state.watchers);
      
      if (filteredWatchers.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.separated(
        key: const ValueKey('loaded'),
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: filteredWatchers.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
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
      itemHeight: 100,
      padding: const EdgeInsets.all(16),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilter = filter);
              },
              selectedColor: AppTheme.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              showCheckmark: false,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
       key: const ValueKey('empty'),
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           const Text('👻', style: TextStyle(fontSize: 64)),
           const SizedBox(height: 16),
           const Text(
             'No watchers found',
             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
           ),
           const SizedBox(height: 8),
           const Text(
             'Create your first agent to start hunting',
             style: TextStyle(color: AppTheme.textSecondary),
           ),
           const SizedBox(height: 24),
           ElevatedButton(
             onPressed: () => context.push('/watchers/create'),
             child: const Text('Create Watcher'),
           ),
         ],
       ),
     );
  }

  List<dynamic> _applyFilter(List<dynamic> watchers) {
    if (_selectedFilter == 'All') return watchers;
    if (_selectedFilter == 'Active') return watchers.where((w) => w.status == 'active').toList();
    if (_selectedFilter == 'Paused') return watchers.where((w) => w.status == 'paused').toList();
    return watchers.where((w) => w.type.toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }
}
