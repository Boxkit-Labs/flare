import 'package:flutter/material.dart';

class LocationPickerSheet extends StatefulWidget {
  final String? selectedCity;
  final String? selectedCountry;

  const LocationPickerSheet({
    super.key,
    this.selectedCity,
    this.selectedCountry,
  });

  static Future<Map<String, String?>?> show(BuildContext context, {String? selectedCity, String? selectedCountry}) {
    return showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPickerSheet(
        selectedCity: selectedCity,
        selectedCountry: selectedCountry,
      ),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  final Map<String, List<Map<String, String>>> _regions = {
    'Nigeria': [
      {'city': 'Lagos', 'country': 'NG'},
      {'city': 'Abuja', 'country': 'NG'},
      {'city': 'Port Harcourt', 'country': 'NG'},
      {'city': 'Ibadan', 'country': 'NG'},
      {'city': 'Kano', 'country': 'NG'},
    ],
    'United States': [
      {'city': 'New York', 'country': 'US'},
      {'city': 'Los Angeles', 'country': 'US'},
      {'city': 'Chicago', 'country': 'US'},
      {'city': 'Miami', 'country': 'US'},
    ],
    'United Kingdom': [
      {'city': 'London', 'country': 'GB'},
      {'city': 'Manchester', 'country': 'GB'},
      {'city': 'Birmingham', 'country': 'GB'},
    ],
    'Other Popular': [
      {'city': 'Toronto', 'country': 'CA'},
      {'city': 'Dubai', 'country': 'AE'},
      {'city': 'Berlin', 'country': 'DE'},
      {'city': 'Paris', 'country': 'FR'},
    ],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Choose Location',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Search
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _filter = v.toLowerCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search city or country...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Anywhere Option
                    if (_filter.isEmpty)
                      _buildCityTile('Anywhere', null, isAnywhere: true),
                    
                    ..._buildFilteredRegions(),

                    // Custom Entry
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        'Custom Location',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                    ),
                    _buildCustomEntry(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildFilteredRegions() {
    final List<Widget> items = [];
    
    _regions.forEach((region, cities) {
      final filteredCities = cities.where((c) =>
          c['city']!.toLowerCase().contains(_filter) ||
          c['country']!.toLowerCase().contains(_filter) ||
          region.toLowerCase().contains(_filter)).toList();

      if (filteredCities.isNotEmpty) {
        items.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text(
              region.toUpperCase(),
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ),
        );
        
        for (final cityData in filteredCities) {
          items.add(_buildCityTile(cityData['city']!, cityData['country']!));
        }
      }
    });

    return items;
  }

  Widget _buildCityTile(String city, String? countryCode, {bool isAnywhere = false}) {
    final isSelected = isAnywhere 
        ? widget.selectedCity == null 
        : (widget.selectedCity == city && widget.selectedCountry == countryCode);

    return ListTile(
      onTap: () => Navigator.pop(context, {'city': isAnywhere ? null : city, 'country': countryCode}),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(
        isAnywhere ? Icons.public : Icons.location_on_outlined,
        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
      ),
      title: Text(
        city,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      trailing: isSelected 
          ? const Icon(Icons.check_circle, color: Color(0xFF6366F1)) 
          : null,
    );
  }

  Widget _buildCustomEntry() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter city name...',
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (v) {
                    if (v.isNotEmpty) {
                      Navigator.pop(context, {'city': v, 'country': 'CUSTOM'});
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Text('🌍', style: TextStyle(fontSize: 16)),
                    Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
