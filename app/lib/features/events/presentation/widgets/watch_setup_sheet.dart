import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/core/utils/currency_formatter.dart';
import 'package:flare_app/features/events/domain/entities/event_entity.dart';
import 'package:flare_app/features/events/presentation/bloc/event_watch_setup_bloc.dart';
import 'package:flare_app/features/events/presentation/bloc/event_watch_setup_event.dart';
import 'package:flare_app/features/events/presentation/bloc/event_watch_setup_state.dart';

class WatchSetupSheet extends StatefulWidget {
  final EventEntity event;

  const WatchSetupSheet({super.key, required this.event});

  static Future<void> show(BuildContext context, EventEntity event) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WatchSetupSheet(event: event),
    );
  }

  @override
  State<WatchSetupSheet> createState() => _WatchSetupSheetState();
}

class _WatchSetupSheetState extends State<WatchSetupSheet> {
  @override
  void initState() {
    super.initState();
    context.read<EventWatchSetupBloc>().add(InitializeWatchSetup(widget.event));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EventWatchSetupBloc, EventWatchSetupState>(
      listener: (context, state) {
        if (state.status == EventWatchSubmissionStatus.success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Watch setup successfully! We will notify you of any changes.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        } else if (state.status == EventWatchSubmissionStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to setup watch'),
              backgroundColor: const Color(0xFFF43F5E),
            ),
          );
        }
      },
      builder: (context, state) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  _buildHeader(state),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildTierSelector(state),
                        const SizedBox(height: 24),
                        _buildAlertConditions(state),
                        const SizedBox(height: 24),
                        _buildFrequencySelector(state),
                        const SizedBox(height: 24),
                        _buildCostEstimate(state),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                  _buildSubmitButton(state),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(EventWatchSetupState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.name,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.event.platformDisplayName,
                      style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierSelector(EventWatchSetupState state) {
    if (widget.event.tiers.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SELECT TIERS', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.event.tiers.map((tier) {
            final isSelected = state.selectedTiers.contains(tier.name);
            return GestureDetector(
              onTap: () => context.read<EventWatchSetupBloc>().add(SelectTier(tier.name, !isSelected)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tier.name,
                  style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAlertConditions(EventWatchSetupState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ALERT CONDITIONS', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 12),
        if (!state.isFreeEvent) ...[
          _AlertToggleCard(
            title: 'Price drops below',
            subtitle: 'Notify when any tier hits target',
            isEnabled: state.priceAlertEnabled,
            onToggle: (v) => context.read<EventWatchSetupBloc>().add(TogglePriceAlert(v)),
            child: Row(
              children: [
                Text(CurrencyFormatter.getCurrencySymbol(state.userCurrency), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(hintText: '0.00', isDense: true, contentPadding: EdgeInsets.zero),
                    onChanged: (v) => context.read<EventWatchSetupBloc>().add(UpdatePriceBelow(double.tryParse(v))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _AlertToggleCard(
            title: 'Price drops by',
            subtitle: 'Relative percentage reduction',
            isEnabled: state.priceAlertEnabled,
            onToggle: (v) => context.read<EventWatchSetupBloc>().add(TogglePriceAlert(v)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [5, 10, 20, 30].map((p) {
                final isSelected = state.priceDropPercentage == p;
                return GestureDetector(
                  onTap: () => context.read<EventWatchSetupBloc>().add(UpdatePriceDropPercentage(p)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$p%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _AlertToggleCard(
          title: 'Availability change',
          subtitle: 'Notify if tickets become available',
          isEnabled: state.availabilityAlertEnabled,
          onToggle: (v) => context.read<EventWatchSetupBloc>().add(ToggleAvailabilityAlert(v)),
        ),
        const SizedBox(height: 12),
        _AlertToggleCard(
          title: 'Almost sold out',
          subtitle: 'Notify when less than 10 tickets remain',
          isEnabled: state.almostSoldOutAlertEnabled,
          onToggle: (v) => context.read<EventWatchSetupBloc>().add(ToggleAlmostSoldOutAlert(v)),
        ),
      ],
    );
  }

  Widget _buildFrequencySelector(EventWatchSetupState state) {
    final frequencies = {
      const Duration(minutes: 15): '15m',
      const Duration(hours: 1): '1h',
      const Duration(hours: 6): '6h',
      const Duration(hours: 24): '24h',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CHECK FREQUENCY', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: frequencies.entries.map((e) {
              final isSelected = state.frequency == e.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.read<EventWatchSetupBloc>().add(SetCheckFrequency(e.key)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        e.value,
                        style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCostEstimate(EventWatchSetupState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Estimated Cost / Day', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
          Text(state.costEstimate, style: const TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(EventWatchSetupState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      decoration: const BoxDecoration(color: Color(0xFF0F172A)),
      child: ElevatedButton(
        onPressed: state.isValid && state.status != EventWatchSubmissionStatus.submitting 
            ? () => context.read<EventWatchSetupBloc>().add(SubmitWatch()) 
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: state.status == EventWatchSubmissionStatus.submitting
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Start Watching', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _AlertToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isEnabled;
  final Function(bool) onToggle;
  final Widget? child;

  const _AlertToggleCard({required this.title, required this.subtitle, required this.isEnabled, required this.onToggle, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isEnabled ? const Color(0xFF6366F1).withOpacity(0.3) : Colors.transparent),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isEnabled,
                onChanged: onToggle,
                activeColor: const Color(0xFF6366F1),
              ),
            ],
          ),
          if (isEnabled && child != null) ...[
            const Divider(color: Colors.white12, height: 24),
            child!,
          ],
        ],
      ),
    );
  }
}
