import 'package:flutter/material.dart';

class RealEstateWatcherForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onChanged;
  final Map<String, dynamic>? initialData;

  const RealEstateWatcherForm({super.key, required this.onChanged, this.initialData});

  @override
  State<RealEstateWatcherForm> createState() => _RealEstateWatcherFormState();
}

class _RealEstateWatcherFormState extends State<RealEstateWatcherForm> {
  String _mode = 'purchase';
  String _propertyType = 'any';
  final _cityController = TextEditingController();
  final _maxPriceController = TextEditingController();
  int _bedrooms = 2;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _mode = widget.initialData!['mode'] ?? 'purchase';
      _propertyType = widget.initialData!['property_type'] ?? 'any';
      _cityController.text = widget.initialData!['city'] ?? 'Austin, TX';
      _maxPriceController.text = widget.initialData!['price_max']?.toString() ?? '500000';
      _bedrooms = widget.initialData!['bedrooms_min'] ?? 2;
    } else {
      _cityController.text = 'Austin, TX';
      _maxPriceController.text = '500000';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateData());
  }

  void _updateData() {
    widget.onChanged({
      'name': 'RE: ${_cityController.text}',
      'type': 'realestate',
      'parameters': {
        'mode': _mode,
        'city': _cityController.text,
        'property_type': _propertyType,
        'bedrooms_min': _bedrooms,
      },
      'alert_conditions': {
        'price_max': double.tryParse(_maxPriceController.text),
        'new_listings': true,
        'price_reductions': true,
        'below_market_deals': true,
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildTypeDrop('Mode', ['purchase', 'rental'], (v) => setState(() => _mode = v!))),
            const SizedBox(width: 16),
            Expanded(child: _buildTypeDrop('Type', ['any', 'apartment', 'house', 'condo'], (v) => setState(() => _propertyType = v!))),
          ],
        ),
        const SizedBox(height: 24),
        const Text('City', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _cityController,
          onChanged: (_) => _updateData(),
          decoration: const InputDecoration(hintText: 'e.g. Austin, TX'),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Max Price', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updateData(),
                    decoration: const InputDecoration(prefixText: '\$ '),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text('Min Bedrooms: $_bedrooms', style: const TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Slider(
                     value: _bedrooms.toDouble(),
                     min: 1, max: 5, divisions: 4,
                     onChanged: (v) {
                       setState(() => _bedrooms = v.toInt());
                       _updateData();
                     },
                   ),
                 ],
               ),
             ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeDrop(String label, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: items.contains(_mode) && label == 'Mode' ? _mode : (items.contains(_propertyType) && label == 'Type' ? _propertyType : items.first),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
          onChanged: (v) {
            onChanged(v);
            _updateData();
          },
        ),
      ],
    );
  }
}
