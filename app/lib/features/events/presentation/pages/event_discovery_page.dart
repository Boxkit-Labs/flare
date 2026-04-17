import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/features/events/presentation/bloc/event_search_bloc.dart';
import 'package:flare_app/features/events/presentation/bloc/event_search_event.dart';
import 'package:flare_app/features/events/presentation/bloc/event_search_state.dart';
import 'package:flare_app/features/events/presentation/widgets/category_chip.dart';
import 'package:flare_app/features/events/presentation/widgets/event_card.dart';
import 'package:flare_app/core/theme/app_theme.dart';

class EventDiscoveryPage extends StatefulWidget {
  const EventDiscoveryPage({super.key});

  @override
  State<EventDiscoveryPage> createState() => _EventDiscoveryPageState();
}

class _EventDiscoveryPageState extends State<EventDiscoveryPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<EventSearchBloc>().add(LoadInitialEvents());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<EventSearchBloc>().add(LoadMoreResults());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Find Events'),
        centerTitle: false,
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          _buildPlatformBanner(),
          _buildActiveFilters(),
          Expanded(
            child: BlocBuilder<EventSearchBloc, EventSearchState>(
              builder: (context, state) {
                if (state is EventSearchInitial) {
                  return _buildInitialBrowse();
                } else if (state is EventSearchLoading && state.events.isEmpty) {
                  return ListView.builder(
                    itemCount: 5,
                    itemBuilder: (_, __) => EventCard.shimmer(),
                  );
                } else if (state is EventSearchEmpty) {
                  return _buildEmptyState();
                } else if (state is EventSearchError && state.events.isEmpty) {
                  return _buildErrorState(state.message);
                }

                return _buildResultsList(state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            onChanged: (value) => context.read<EventSearchBloc>().add(UpdateQuery(value)),
            decoration: InputDecoration(
              hintText: 'Search artists, venues, or cities...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          // Filter Horizontal Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterButton(
                  icon: Icons.location_on_outlined,
                  label: 'Lagos, Nigeria', // Mock for now
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                const CategoryChip(category: 'Music', emoji: '🎵', isSelected: false),
                const SizedBox(width: 8),
                const CategoryChip(category: 'Tech', emoji: '💻', isSelected: false),
                const SizedBox(width: 8),
                _FilterButton(
                  icon: Icons.monetization_on_outlined,
                  label: 'Free Only',
                  onTap: () => context.read<EventSearchBloc>().add(ToggleFreeOnly()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return BlocBuilder<EventSearchBloc, EventSearchState>(
      builder: (context, state) {
        final filters = state.filters;
        final activeFilters = <Widget>[];

        if (filters.query != null && filters.query!.isNotEmpty) {
          activeFilters.add(_FilterPill(label: filters.query!, onRemove: () => context.read<EventSearchBloc>().add(const UpdateQuery(''))));
        }
        if (filters.isFreeOnly) {
          activeFilters.add(_FilterPill(label: 'Free Only', onRemove: () => context.read<EventSearchBloc>().add(ToggleFreeOnly())));
        }

        if (activeFilters.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: activeFilters,
                ),
              ),
              TextButton(
                onPressed: () => context.read<EventSearchBloc>().add(ClearFilters()),
                child: const Text('Clear All', style: TextStyle(color: Color(0xFFF43F5E), fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlatformBanner() {
    return BlocBuilder<EventSearchBloc, EventSearchState>(
      builder: (context, state) {
        final platform = state.filters.platform;
        if (platform != null && platform.toLowerCase() != 'eventbrite') {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF6366F1)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Note: Eventbrite offers the best coverage for events in your region.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildResultsList(EventSearchState state) {
    return RefreshIndicator(
      onRefresh: () async => context.read<EventSearchBloc>().add(SearchEvents()),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: state.events.length + (state is EventSearchLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < state.events.length) {
            final event = state.events[index];
            return EventCard(
              event: event,
              onTap: () => context.push(
                '/events/detail/${event.platform}/${event.externalId}',
                extra: event,
              ),
            );
          } else {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }

  Widget _buildInitialBrowse() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Categories', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _CategoryCard(label: 'Comedy', emoji: '😂', color: const Color(0xFFF59E0B)),
              _CategoryCard(label: 'Music', emoji: '🎵', color: const Color(0xFF6366F1)),
              _CategoryCard(label: 'Nightlife', emoji: '💃', color: const Color(0xFFF43F5E)),
              _CategoryCard(label: 'Business', emoji: '📈', color: const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Upcoming Popular', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          // Mock data for initial browse
          // In real app, this would be a separate bloc loading popular events
          const Center(child: Text('Discover something new today', style: TextStyle(color: Color(0xFF64748B)))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Color(0xFF64748B)),
          const SizedBox(height: 16),
          const Text('No events found', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Try adjusting your filters or query', style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.read<EventSearchBloc>().add(ClearFilters()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: const Text('Clear All Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFF43F5E)),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.read<EventSearchBloc>().add(SearchEvents()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF6366F1)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterPill({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Color(0xFF6366F1)),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;

  const _CategoryCard({required this.label, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
