import 'package:flutter/material.dart';
import 'package:ghost_app/core/theme/app_theme.dart';

class JobWatcherForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onChanged;

  const JobWatcherForm({super.key, required this.onChanged});

  @override
  State<JobWatcherForm> createState() => _JobWatcherFormState();
}

class _JobWatcherFormState extends State<JobWatcherForm> {
  final _nameController = TextEditingController();
  final _keywordController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final List<String> _keywords = [];
  bool _isRemote = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateData);
    _locationController.addListener(_updateData);
    _salaryController.addListener(_updateData);
    _nameController.text = 'Job Watch';
  }

  void _updateData() {
    if (_keywords.isNotEmpty && _nameController.text == 'Job Watch') {
      _nameController.text = 'Jobs: ${_keywords.join(", ")}';
    }

    widget.onChanged({
      'name': _nameController.text,
      'parameters': {
        'keywords': _keywords,
        'location': _isRemote ? 'Remote' : _locationController.text,
        'is_remote': _isRemote,
      },
      'alert_conditions': {
        'min_salary': double.tryParse(_salaryController.text),
      }
    });
  }

  void _addKeyword(String value) {
    if (value.trim().isNotEmpty && !_keywords.contains(value.trim())) {
      setState(() {
        _keywords.add(value.trim());
      });
      _keywordController.clear();
      _updateData();
    }
  }

  void _removeKeyword(String value) {
    setState(() {
      _keywords.remove(value);
    });
    _updateData();
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
        const Text('Search Keywords', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _keywordController,
          onSubmitted: _addKeyword,
          decoration: InputDecoration(
            hintText: 'e.g. Flutter Developer, Designer',
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addKeyword(_keywordController.text),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _keywords.map((keyword) {
            return Chip(
              label: Text(keyword),
              onDeleted: () => _removeKeyword(keyword),
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              deleteIconColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: const BorderSide(color: AppTheme.primary),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Remote only?', style: TextStyle(fontWeight: FontWeight.bold)),
            Switch(
              value: _isRemote,
              onChanged: (val) {
                setState(() => _isRemote = val);
                _updateData();
              },
              activeTrackColor: AppTheme.secondary.withValues(alpha: 0.5),
              activeThumbColor: AppTheme.secondary,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!_isRemote) ...[
          const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: 'e.g. San Francisco',
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
        ],
        const Text('Min Annual Salary (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _salaryController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '\$ ',
            hintText: 'Notify above salary',
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
