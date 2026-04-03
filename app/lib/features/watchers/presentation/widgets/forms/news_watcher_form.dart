import 'package:flutter/material.dart';
import 'package:ghost_app/core/theme/app_theme.dart';

class NewsWatcherForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onChanged;
  final Map<String, dynamic>? initialData;

  const NewsWatcherForm({super.key, required this.onChanged, this.initialData});

  @override
  State<NewsWatcherForm> createState() => _NewsWatcherFormState();
}

class _NewsWatcherFormState extends State<NewsWatcherForm> {
  final _nameController = TextEditingController();
  final _keywordController = TextEditingController();
  final List<String> _keywords = [];
  int _minArticles = 1;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateData);
    _nameController.text = 'News Watch';

    if (widget.initialData != null) {
      if (widget.initialData!['keywords'] != null) {
        _keywords.addAll(List<String>.from(widget.initialData!['keywords']));
      }
      _minArticles = widget.initialData!['min_articles'] ?? 1;
    }
  }

  void _updateData() {
    if (_keywords.isNotEmpty && _nameController.text == 'News Watch') {
      _nameController.text = 'News: ${_keywords.first}';
    }

    widget.onChanged({
      'name': _nameController.text,
      'parameters': {
        'keywords': _keywords,
      },
      'alert_conditions': {
        'min_articles': _minArticles,
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
        const Text('Keywords', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _keywordController,
          onSubmitted: _addKeyword,
          decoration: InputDecoration(
            hintText: 'Type keyword and press Enter',
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
        const Text('Alert Threshold', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _minArticles,
              isExpanded: true,
              dropdownColor: AppTheme.surface,
              items: [1, 2, 3, 5].map((val) {
                return DropdownMenuItem<int>(
                  value: val,
                  child: Text('Notify after $val matching articles'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _minArticles = val);
                  _updateData();
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
