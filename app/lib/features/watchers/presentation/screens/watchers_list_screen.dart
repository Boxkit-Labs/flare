import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_app/core/theme/app_theme.dart';
import 'package:ghost_app/core/widgets/shimmer_placeholder.dart';
import 'package:ghost_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ghost_app/features/watchers/presentation/bloc/watchers_bloc.dart';
import 'package:ghost_app/features/watchers/presentation/bloc/watchers_event.dart';
import 'package:ghost_app/features/watchers/presentation/bloc/watchers_state.dart';
import 'package:ghost_app/features/watchers/presentation/widgets/watcher_list_tile.dart';

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
    final userId = (context.read<AuthBloc>().state as dynamic).user.userId;
    context.read<WatchersBloc>().add(LoadWatchers(userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchers', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false, // No back button as it's a main tab
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
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: BlocBuilder<WatchersBloc, WatchersState>(
                builder: (context, state) {
                  if (state is WatchersLoaded) {
                    final filteredWatchers = _applyFilter(state.watchers);
                    
                    if (filteredWatchers.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.separated(
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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Failed to load watchers'),
                          ElevatedButton(
                            onPressed: _refresh,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildShimmerList();
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

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: ShimmerPlaceholder(width: double.infinity, height: 100, borderRadius: 12),
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
