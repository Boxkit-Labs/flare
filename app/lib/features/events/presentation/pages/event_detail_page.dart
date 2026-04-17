// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/features/events/domain/entities/event_entity.dart';
import 'package:flare_app/features/events/presentation/bloc/event_detail_bloc.dart';
import 'package:flare_app/features/events/presentation/bloc/event_detail_event.dart';
import 'package:flare_app/features/events/presentation/bloc/event_detail_state.dart';
import 'package:flare_app/features/events/presentation/widgets/platform_badge.dart';
import 'package:flare_app/features/events/presentation/widgets/countdown_pill.dart';
import 'package:flare_app/features/events/presentation/widgets/ticket_tier_card.dart';

class EventDetailPage extends StatefulWidget {
  final String platform;
  final String externalId;
  final EventEntity? initialEvent;

  const EventDetailPage({
    super.key,
    required this.platform,
    required this.externalId,
    this.initialEvent,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<EventDetailBloc>().add(
      LoadEventDetail(
        platform: widget.platform,
        externalId: widget.externalId,
        initialEntity: widget.initialEvent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventDetailBloc, EventDetailState>(
      builder: (context, state) {
        final event = state.event;

        if (event == null && state is EventDetailLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (event == null && state is EventDetailError) {
          return Scaffold(body: Center(child: Text(state.message)));
        }

        if (event == null) return const Scaffold();

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildAppBar(context, event),
                  _buildInfoSection(event),
                  _buildTicketsSection(event),
                  _buildVenueSection(event),
                  const SliverToBoxExtent(extent: 120), // Bottom bar space
                ],
              ),
              _buildStickyBottomBar(event),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, EventEntity event) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        centerTitle: false,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final isCollapsed = constraints.maxHeight <= kToolbarHeight + 40;
            return isCollapsed
                ? Text(
                    event.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox.shrink();
          },
        ),
        background: Hero(
          tag: 'event_${event.platform}_${event.externalId}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (event.imageUrl != null)
                Image.network(event.imageUrl!, fit: BoxFit.cover)
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF0F172A).withOpacity(0.8),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PlatformBadge(platform: event.platformDisplayName),
                    CountdownPill(daysUntil: event.daysUntil),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(EventEntity event) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.calendar_today,
              label: event.formattedFullDate,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: '${event.venue}, ${event.city}',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.category_outlined,
              label: '${event.categoryEmoji} ${event.category}',
            ),
            const SizedBox(height: 24),
            const Text(
              'About Event',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.description ?? 'No description available for this event.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsSection(EventEntity event) {
    final sortedTiers = List.from(event.tiers)
      ..sort((a, b) => (b.available ? 1 : 0).compareTo(a.available ? 1 : 0));

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              'Ticket Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...sortedTiers.map(
            (tier) => TicketTierCard(tier: tier, onPlatformLinkTap: () {}),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueSection(EventEntity event) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Venue Information',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(event.venue, style: const TextStyle(color: Colors.white70)),
              Text(event.city, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {},
                child: const Row(
                  children: [
                    Icon(
                      Icons.directions_outlined,
                      size: 16,
                      color: Color(0xFF6366F1),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Get Directions',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickyBottomBar(EventEntity event) {
    final isPast = event.date.isBefore(DateTime.now());
    final isCancelled = event.status == 'cancelled';
    final canBook = !isPast && !isCancelled && event.status != 'sold_out';

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canBook ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.white10,
                ),
                child: Text(
                  isCancelled
                      ? 'Cancelled'
                      : (isPast
                            ? 'Past Event'
                            : (event.isFree ? 'Get Free Ticket' : 'Book Now')),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_active_outlined,
                  color: Color(0xFF6366F1),
                ),
                tooltip: 'Watch Price',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6366F1)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class SliverToBoxExtent extends StatelessWidget {
  final double extent;
  const SliverToBoxExtent({super.key, required this.extent});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: SizedBox(height: extent));
  }
}
