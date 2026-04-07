import 'package:flutter/material.dart';
import 'package:flare_app/core/theme/app_theme.dart';

class JobWatcherForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onChanged;
  final Map<String, dynamic>? initialData;

  const JobWatcherForm({super.key, required this.onChanged, this.initialData});

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
    _nameController.text = 'Job Watch';

    if (widget.initialData != null) {
      if (widget.initialData!['keywords'] != null) {
        _keywords.addAll(List<String>.from(widget.initialData!['keywords']));
      }
      _locationController.text = widget.initialData!['location'] ?? '';
      _isRemote = widget.initialData!['is_remote'] ?? false;
      _salaryController.text = widget.initialData!['min_salary']?.toString() ?? '';
    }

    _nameController.addListener(_updateData);
    _locationController.addListener(_updateData);
    _salaryController.addListener(_updateData);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateData());
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
          decoration: const InputDecoration(),
        ),
        const SizedBox(height: 20),
        const Text('Search Keywords', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _keywordController,
          onSubmitted: _addKeyword,
          decoration: InputDecoration(
            hintText: 'e.g. Flutter Developer, Designer',
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
            decoration: const InputDecoration(
              hintText: 'e.g. San Francisco',
            ),
          ),
          const SizedBox(height: 20),
        ],
        const Text('Min Annual Salary (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _salaryController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: '\$ ',
            hintText: 'Notify above salary',
          ),
        ),
      ],
    );
  }
}
