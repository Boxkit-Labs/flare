import 'package:flutter/material.dart';
import 'package:flare_app/core/utils/currency_formatter.dart';
import 'package:flare_app/features/events/presentation/bloc/event_search_filters.dart';
import 'package:flare_app/features/events/presentation/widgets/category_chip.dart';
import 'package:flare_app/features/events/presentation/widgets/location_picker_sheet.dart';

class AdvancedFilterSheet extends StatefulWidget {
  final EventSearchFilters initialFilters;

  const AdvancedFilterSheet({super.key, required this.initialFilters});

  static Future<EventSearchFilters?> show(BuildContext context, EventSearchFilters initialFilters) {
    return showModalBottomSheet<EventSearchFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedFilterSheet(initialFilters: initialFilters),
    );
  }

  @override
  State<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<AdvancedFilterSheet> {
  late EventSearchFilters _tempFilters;
  late String _currency;

  @override
  void initState() {
    super.initState();
    _tempFilters = widget.initialFilters;
    _currency = CurrencyFormatter.detectUserCurrency();
  }

  void _updateLocation() async {
    final result = await LocationPickerSheet.show(
      context, 
      selectedCity: _tempFilters.city, 
      selectedCountry: _tempFilters.country
    );
    if (result != null) {
      setState(() {
        _tempFilters = _tempFilters.copyWith(
          city: result['city'],
          country: result['country'],
        );
        // Sync currency if location changes
        _currency = CurrencyFormatter.detectUserCurrency();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSection('Location', child: _buildLocationTile()),
                    _buildSection('Platforms', child: _buildPlatformGrid()),
                    _buildSection('Categories', child: _buildCategoryWrap()),
                    _buildSection('Date Range', child: _buildDateOptions()),
                    _buildSection('Price Range', child: _buildPriceSlider()),
                    const SizedBox(height: 100), // Space for button
                  ],
                ),
              ),
              _buildApplyButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => setState(() => _tempFilters = const EventSearchFilters()),
            child: const Text('Reset', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          const Text('Filters', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ),
        child,
        const Divider(color: Colors.white12, height: 32),
      ],
    );
  }

  Widget _buildLocationTile() {
    return GestureDetector(
      onTap: _updateLocation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFF6366F1)),
            const SizedBox(width: 12),
            Text(
              _tempFilters.city ?? 'Anywhere',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformGrid() {
    final platforms = [
      {'id': 'ticketmaster', 'name': 'Ticketmaster', 'info': '500+ events'},
      {'id': 'eventbrite', 'name': 'Eventbrite', 'info': '1.2k events'},
      {'id': 'skiddle', 'name': 'Skiddle', 'info': '200+ events'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: platforms.map((p) {
        final isSelected = _tempFilters.platform == p['id'];
        return GestureDetector(
          onTap: () => setState(() => _tempFilters = _tempFilters.copyWith(platform: isSelected ? null : p['id'])),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? const Color(0xFF6366F1) : Colors.transparent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name']!, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF94A3B8), fontWeight: FontWeight.w800)),
                Text(p['info']!, style: TextStyle(color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF64748B), fontSize: 10)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryWrap() {
    final categories = [
      {'name': 'Music', 'emoji': '🎵'},
      {'name': 'Concerts', 'emoji': '🎸'},
      {'name': 'Nightlife', 'emoji': '🍸'},
      {'name': 'Food', 'emoji': '🍕'},
      {'name': 'Tech', 'emoji': '💻'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((c) {
        return CategoryChip(
          category: c['name']!,
          emoji: c['emoji']!,
          isSelected: _tempFilters.category == c['name'],
          onTap: () => setState(() => _tempFilters = _tempFilters.copyWith(category: _tempFilters.category == c['name'] ? null : c['name'])),
        );
      }).toList(),
    );
  }

  Widget _buildDateOptions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _DateQuickChip(label: 'Today', onTap: () {}),
            _DateQuickChip(label: 'Tomorrow', onTap: () {}),
            _DateQuickChip(label: 'This Weekend', onTap: () {}),
          ],
        ),
        const SizedBox(height: 12),
        _DateQuickChip(label: 'Choose Custom Date...', icon: Icons.calendar_month, fullWidth: true, onTap: () {}),
      ],
    );
  }

  Widget _buildPriceSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Price Range (${CurrencyFormatter.getCurrencySymbol(_currency)})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Text('Any', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ],
        ),
        RangeSlider(
          values: const RangeValues(0, 1000),
          min: 0,
          max: 1000,
          activeColor: const Color(0xFF6366F1),
          inactiveColor: const Color(0xFF1E293B),
          onChanged: (v) {},
        ),
        SwitchListTile(
          title: const Text('Only show free events', style: TextStyle(color: Colors.white, fontSize: 14)),
          value: _tempFilters.isFreeOnly,
          onChanged: (v) => setState(() => _tempFilters = _tempFilters.copyWith(isFreeOnly: v)),
          activeColor: const Color(0xFF10B981),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -10))],
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, _tempFilters),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('Show Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _DateQuickChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool fullWidth;
  final VoidCallback onTap;

  const _DateQuickChip({required this.label, this.icon, this.fullWidth = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: const Color(0xFF6366F1)), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
