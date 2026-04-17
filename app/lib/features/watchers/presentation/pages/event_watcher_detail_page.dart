import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/features/events/domain/entities/event_entity.dart';
import 'package:flare_app/features/events/presentation/bloc/event_price_history_bloc.dart';
import 'package:flare_app/features/events/presentation/bloc/event_price_history_event.dart';
import 'package:flare_app/features/events/presentation/bloc/event_price_history_state.dart';
import 'package:flare_app/features/events/presentation/widgets/platform_badge.dart';
import 'package:flare_app/features/events/presentation/widgets/countdown_pill.dart';
import 'package:flare_app/features/events/presentation/widgets/event_price_history_chart.dart';
import 'package:flare_app/features/events/presentation/widgets/price_change_indicator.dart';

class EventWatcherDetailPage extends StatefulWidget {
  final EventEntity event;
  final String watcherId;

  const EventWatcherDetailPage({
    super.key,
    required this.event,
    required this.watcherId,
  });

  @override
  State<EventWatcherDetailPage> createState() => _EventWatcherDetailPageState();
}

class _EventWatcherDetailPageState extends State<EventWatcherDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<EventPriceHistoryBloc>().add(LoadPriceHistory(
          platform: widget.event.platform,
          externalId: widget.event.externalId,
        ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<EventPriceHistoryBloc>().add(LoadPriceHistory(
                platform: widget.event.platform,
                externalId: widget.event.externalId,
              ));
        },
        color: const Color(0xFF6366F1),
        backgroundColor: const Color(0xFF1E293B),
        child: CustomScrollView(
          slivers: [
            _buildHeroHeader(),
            _buildAlertStatusHeader(),
            _buildPriceCards(),
            _buildChartSection(),
            _buildTabs(),
            _buildTabContent(),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildHeroHeader() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: const Color(0xFF0F172A),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.event.imageUrl != null)
              Image.network(widget.event.imageUrl!, fit: BoxFit.cover)
            else
              Container(color: const Color(0xFF1E293B)),
            Container(color: Colors.black45),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PlatformBadge(platform: widget.event.platformDisplayName),
                      CountdownPill(daysUntil: widget.event.daysUntil),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.event.name,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(widget.event.venue, style: TextStyle(color: Colors.white.withOpacity(0.7))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertStatusHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active & Monitoring', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('Checking every 15 minutes', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Text('ID: #8321', style: TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCards() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: widget.event.tiers.length,
          itemBuilder: (context, index) {
            final tier = widget.event.tiers[index];
            return _buildAnimatedEntry(
              index,
              Container(
                width: 150,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tier.name, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1),
                    const Spacer(),
                    Text(tier.displayPrice, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    const Row(
                      children: [
                        PriceChangeIndicator(change: 2.1, direction: PriceDirection.down),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedEntry(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildChartSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PRICE HISTORY', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                Text('Last 7 Days', style: TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            BlocBuilder<EventPriceHistoryBloc, EventPriceHistoryState>(
              builder: (context, state) {
                if (state is EventPriceHistoryLoaded) {
                  return EventPriceHistoryChart(groupedData: state.filteredData, currency: widget.event.currency);
                }
                return const AspectRatio(aspectRatio: 1.7, child: Center(child: CircularProgressIndicator()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabDelegate(
        child: Container(
          color: const Color(0xFF0F172A),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF6366F1),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF6366F1),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [Tab(text: 'Conditions'), Tab(text: 'Stats')],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: [
          _buildConditionsTab(),
          _buildStatsTab(),
        ][_tabController.index],
      ),
    );
  }

  Widget _buildConditionsTab() {
    return Column(
      children: [
        _buildConditionRow('Price < ₦20,000', true),
        _buildConditionRow('Price drop > 10%', false),
        _buildConditionRow('Tickets restocked', true),
      ],
    );
  }

  Widget _buildConditionRow(String label, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.notifications_active, color: isActive ? const Color(0xFF6366F1) : const Color(0xFF64748B), size: 18),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: isActive ? Colors.white : const Color(0xFF64748B))),
          const Spacer(),
          Text(isActive ? 'ENABLED' : 'DISABLED', style: TextStyle(color: isActive ? const Color(0xFF10B981) : const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return const Column(
      children: [
        Text('Monitoring stats will appear here.', style: TextStyle(color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          _ActionButton(icon: Icons.edit_outlined, onTap: () {}),
          const SizedBox(width: 8),
          _ActionButton(icon: Icons.pause_circle_outline, onTap: () {}),
          const SizedBox(width: 8),
          _ActionButton(icon: Icons.delete_outline, color: const Color(0xFFF43F5E), onTap: () {}),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color ?? const Color(0xFF6366F1), size: 20),
      ),
    );
  }
}

class _SliverTabDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverTabDelegate({required this.child});

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(_SliverTabDelegate oldDelegate) => false;
}
