import 'package:flutter/material.dart';

class StockWatcherForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onChanged;
  final Map<String, dynamic>? initialData;

  const StockWatcherForm({super.key, required this.onChanged, this.initialData});

  @override
  State<StockWatcherForm> createState() => _StockWatcherFormState();
}

class _StockWatcherFormState extends State<StockWatcherForm> {
  String _mode = 'quote'; // quote, portfolio, events
  final _symbolsController = TextEditingController();
  final _priceBelowController = TextEditingController();
  final _priceAboveController = TextEditingController();
  final _changePercentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _mode = widget.initialData!['mode'] ?? 'quote';
      _symbolsController.text = (widget.initialData!['symbols'] as List?)?.join(', ') ?? '';
      _priceBelowController.text = widget.initialData!['price_below']?.toString() ?? '';
      _priceAboveController.text = widget.initialData!['price_above']?.toString() ?? '';
      _changePercentController.text = widget.initialData!['change_percent']?.toString() ?? '5.0';
    } else {
      _symbolsController.text = 'AAPL, TSLA, NVDA';
      _changePercentController.text = '5.0';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateData());
  }

  void _updateData() {
    final symbols = _symbolsController.text.split(',').map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toList();
    
    widget.onChanged({
      'name': 'Stock Watcher${symbols.isNotEmpty ? ": ${symbols.first}" : ""}',
      'type': 'stock',
      'parameters': {
        'mode': _mode,
        'symbols': symbols,
      },
      'alert_conditions': {
        'price_below': double.tryParse(_priceBelowController.text),
        'price_above': double.tryParse(_priceAboveController.text),
        'change_percent': double.tryParse(_changePercentController.text) ?? 5.0,
        'volume_spike': true,
        'earnings_alerts': _mode == 'events',
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mode', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildModeChip('Quote', 'quote'),
            const SizedBox(width: 8),
            _buildModeChip('Portfolio', 'portfolio'),
            const SizedBox(width: 8),
            _buildModeChip('Events', 'events'),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Symbols (comma separated)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _symbolsController,
          onChanged: (_) => _updateData(),
          decoration: const InputDecoration(hintText: 'e.g. AAPL, TSLA, NVDA'),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text('Price Below', style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   TextField(
                     controller: _priceBelowController,
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
                   const Text('Price Above', style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   TextField(
                     controller: _priceAboveController,
                     keyboardType: TextInputType.number,
                     onChanged: (_) => _updateData(),
                     decoration: const InputDecoration(prefixText: '\$ '),
                   ),
                 ],
               ),
             ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Alert on Change %', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _changePercentController,
          keyboardType: TextInputType.number,
          onChanged: (_) => _updateData(),
          decoration: const InputDecoration(suffixText: '%'),
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
