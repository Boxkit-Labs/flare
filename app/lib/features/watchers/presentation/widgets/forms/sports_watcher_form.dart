import 'package:flutter/material.dart';

class SportsWatcherForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onChanged;
  final Map<String, dynamic>? initialData;

  const SportsWatcherForm({super.key, required this.onChanged, this.initialData});

  @override
  State<SportsWatcherForm> createState() => _SportsWatcherFormState();
}

class _SportsWatcherFormState extends State<SportsWatcherForm> {
  String _mode = 'tickets'; // tickets, scores, events
  final _teamController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _mode = widget.initialData!['mode'] ?? 'tickets';
      _teamController.text = widget.initialData!['team'] ?? 'Warriors';
      _maxPriceController.text = widget.initialData!['price_max']?.toString() ?? '200';
      _cityController.text = widget.initialData!['city'] ?? 'San Francisco, CA';
    } else {
      _teamController.text = 'Warriors';
      _maxPriceController.text = '200';
      _cityController.text = 'San Francisco, CA';
    }
    _updateData();
  }

  void _updateData() {
    widget.onChanged({
      'name': 'Sports: ${_teamController.text}',
      'type': 'sports',
      'parameters': {
        'mode': _mode,
        'team': _teamController.text,
        'city': _cityController.text,
      },
      'alert_conditions': {
        'price_max': double.tryParse(_maxPriceController.text),
        'score_changes': true,
        'price_drops': true,
        'new_events': true,
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
            _buildModeChip('Tickets', 'tickets'),
            const SizedBox(width: 8),
            _buildModeChip('Scores', 'scores'),
            const SizedBox(width: 8),
            _buildModeChip('Events', 'events'),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Team / Event Name', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _teamController,
          onChanged: (_) => _updateData(),
          decoration: const InputDecoration(hintText: 'e.g. Warriors, Taylor Swift'),
        ),
        const SizedBox(height: 24),
        const Text('City (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _cityController,
          onChanged: (_) => _updateData(),
          decoration: const InputDecoration(hintText: 'e.g. San Francisco, CA'),
        ),
        const SizedBox(height: 24),
        const Text('Max Price', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _maxPriceController,
          keyboardType: TextInputType.number,
          onChanged: (_) => _updateData(),
          decoration: const InputDecoration(prefixText: '\$ '),
        ),
      ],
    );
  }

  Widget _buildModeChip(String label, String value) {
    final isSelected = _mode == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _mode = value);
          _updateData();
        }
      },
    );
  }
}
