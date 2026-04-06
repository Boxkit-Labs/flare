import 'package:flutter/material.dart';

class ProductWatcherForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onChanged;
  final Map<String, dynamic>? initialData;

  const ProductWatcherForm({super.key, required this.onChanged, this.initialData});

  @override
  State<ProductWatcherForm> createState() => _ProductWatcherFormState();
}

class _ProductWatcherFormState extends State<ProductWatcherForm> {
  final _nameController = TextEditingController();
  final _productController = TextEditingController();
  final _currentPriceController = TextEditingController();
  final _alertPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      _productController.text = widget.initialData!['product_name'] ?? '';
      _currentPriceController.text = widget.initialData!['current_price']?.toString() ?? '';
      _alertPriceController.text = widget.initialData!['price_below']?.toString() ?? '';
    }

    _productController.addListener(_updateData);
    _currentPriceController.addListener(_updateData);
    _alertPriceController.addListener(_updateData);
    _nameController.addListener(_updateNameManually);
  }

  bool _isManualName = false;

  void _updateNameManually() {
    if (_nameController.text.isNotEmpty && !_isManualName) {
      if (_nameController.text != _productController.text) {
        _isManualName = true;
      }
    }
    _updateData();
  }

  void _updateData() {
    if (!_isManualName) {
      _nameController.text = _productController.text.isEmpty ? 'Product Watcher' : _productController.text;
    }

    widget.onChanged({
      'name': _nameController.text,
      'parameters': {
        'product_name': _productController.text,
        'current_price': double.tryParse(_currentPriceController.text),
      },
      'alert_conditions': {
        'price_below': double.tryParse(_alertPriceController.text),
      }
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
          decoration: const InputDecoration(),
        ),
        const SizedBox(height: 20),
        const Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _productController,
          decoration: const InputDecoration(
            hintText: 'e.g. Sony WH-1000XM5',
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Price', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _currentPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: '\$ ',
                      hintText: '0.00',
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
                  const Text('Alert Target', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _alertPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: '\$ ',
                      hintText: 'Notify below',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
