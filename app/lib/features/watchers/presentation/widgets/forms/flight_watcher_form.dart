import 'package:flutter/material.dart';
import 'package:ghost_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class FlightWatcherForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onChanged;
  final Map<String, dynamic>? initialData;

  const FlightWatcherForm({super.key, required this.onChanged, this.initialData});

  @override
  State<FlightWatcherForm> createState() => _FlightWatcherFormState();
}

class _FlightWatcherFormState extends State<FlightWatcherForm> {
  final _nameController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime? _departureDate;
  DateTime? _returnDate;

  @override
  void initState() {
    super.initState();
    _originController.addListener(_updateData);
    _destinationController.addListener(_updateData);
    _priceController.addListener(_updateData);
    _nameController.addListener(_updateNameManually);

    if (widget.initialData != null) {
      _originController.text = widget.initialData!['origin'] ?? '';
      _destinationController.text = widget.initialData!['destination'] ?? '';
      if (widget.initialData!['departure_date'] != null) {
        _departureDate = DateTime.parse(widget.initialData!['departure_date']);
      }
      if (widget.initialData!['return_date'] != null) {
        _returnDate = DateTime.parse(widget.initialData!['return_date']);
      }
      _priceController.text = widget.initialData!['price_below']?.toString() ?? '';
    }
  }

  bool _isManualName = false;

  void _updateNameManually() {
    if (_nameController.text.isNotEmpty && !_isManualName) {
      if (_nameController.text != _getDefaultName()) {
         _isManualName = true;
      }
    }
    _updateData();
  }

  String _getDefaultName() {
    if (_destinationController.text.isEmpty) return 'Flight Watcher';
    return 'Flight to ${_destinationController.text}';
  }

  void _updateData() {
    if (!_isManualName) {
      _nameController.text = _getDefaultName();
    }

    widget.onChanged({
      'name': _nameController.text,
      'parameters': {
        'origin': _originController.text,
        'destination': _destinationController.text,
        'departure_date': _departureDate?.toIso8601String(),
        'return_date': _returnDate?.toIso8601String(),
      },
      'alert_conditions': {
        'price_below': double.tryParse(_priceController.text),
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isDeparture) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departureDate = picked;
        } else {
          _returnDate = picked;
        }
      });
      _updateData();
    }
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
            hintText: 'e.g. Summer Trip to Tokyo',
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Origin', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _originController,
                    decoration: InputDecoration(
                      hintText: 'JFK, LAX...',
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Destination', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _destinationController,
                    decoration: InputDecoration(
                      hintText: 'SFO, NRT...',
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Travel Dates', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectDate(context, true),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(_departureDate == null ? 'Departure' : DateFormat('MMM d').format(_departureDate!)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectDate(context, false),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(_returnDate == null ? 'Return' : DateFormat('MMM d').format(_returnDate!)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Alert Condition', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '\$ ',
            hintText: 'Notify when price drops below',
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
