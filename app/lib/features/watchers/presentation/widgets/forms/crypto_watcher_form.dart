import 'package:flutter/material.dart';
import 'package:ghost_app/core/theme/app_theme.dart';

class CryptoWatcherForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onChanged;
  final Map<String, dynamic>? initialData;

  const CryptoWatcherForm({super.key, required this.onChanged, this.initialData});

  @override
  State<CryptoWatcherForm> createState() => _CryptoWatcherFormState();
}

class _CryptoWatcherFormState extends State<CryptoWatcherForm> {
  final _nameController = TextEditingController();
  final Set<String> _selectedCoins = {'ETH', 'BTC'};
  final Map<String, TextEditingController> _aboveControllers = {};
  final Map<String, TextEditingController> _belowControllers = {};
  final _changeController = TextEditingController();

  final List<String> _coins = ['XLM', 'ETH', 'BTC', 'SOL', 'XRP'];

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Crypto Watch';
    _changeController.addListener(_updateData);
    _nameController.addListener(_updateData);
    for (var coin in _coins) {
      _aboveControllers[coin] = TextEditingController()..addListener(_updateData);
      _belowControllers[coin] = TextEditingController()..addListener(_updateData);
    }

    if (widget.initialData != null) {
      if (widget.initialData!['coins'] != null) {
        _selectedCoins.clear();
        _selectedCoins.addAll(List<String>.from(widget.initialData!['coins']));
      }
      _changeController.text = widget.initialData!['change_24h_percent']?.toString() ?? '';
      for (var coin in _selectedCoins) {
         _aboveControllers[coin]?.text = widget.initialData!['${coin.toLowerCase()}_above']?.toString() ?? '';
         _belowControllers[coin]?.text = widget.initialData!['${coin.toLowerCase()}_below']?.toString() ?? '';
      }
    }
  }

  void _updateData() {
    final Map<String, dynamic> alerts = {
      'change_24h_percent': double.tryParse(_changeController.text),
    };

    for (var coin in _selectedCoins) {
      alerts['${coin.toLowerCase()}_above'] = double.tryParse(_aboveControllers[coin]!.text);
      alerts['${coin.toLowerCase()}_below'] = double.tryParse(_belowControllers[coin]!.text);
    }

    widget.onChanged({
      'name': _nameController.text,
      'parameters': {
        'coins': _selectedCoins.toList(),
      },
      'alert_conditions': alerts,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Watcher Name', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Target Coins', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _coins.map((coin) {
            final isSelected = _selectedCoins.contains(coin);
            return FilterChip(
              label: Text(coin),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCoins.add(coin);
                  } else {
                    _selectedCoins.remove(coin);
                  }
                });
                _updateData();
              },
              selectedColor: AppTheme.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: isSelected ? const BorderSide(color: AppTheme.primary) : BorderSide.none,
              showCheckmark: false,
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text('General Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _changeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: '%',
            hintText: 'Notify if 24h change exceeds',
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
        Theme(
           data: ThemeData.dark().copyWith(
             dividerColor: Colors.transparent,
           ),
           child: ExpansionTile(
            title: const Text('Price Thresholds (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            tilePadding: EdgeInsets.zero,
            children: _selectedCoins.map((coin) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coin, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _aboveControllers[coin],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixText: '> ',
                              hintText: 'Above \$',
                              filled: true,
                              fillColor: AppTheme.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _belowControllers[coin],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixText: '< ',
                              hintText: 'Below \$',
                              filled: true,
                              fillColor: AppTheme.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
