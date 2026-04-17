import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_bloc.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_event.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_state.dart';
import 'package:flare_app/features/watchers/presentation/widgets/forms/flight_watcher_form.dart';
import 'package:flare_app/features/watchers/presentation/widgets/forms/crypto_watcher_form.dart';
import 'package:flare_app/features/watchers/presentation/widgets/forms/news_watcher_form.dart';
import 'package:flare_app/features/watchers/presentation/widgets/forms/product_watcher_form.dart';
import 'package:flare_app/features/watchers/presentation/widgets/forms/job_watcher_form.dart';
import 'package:flare_app/features/watchers/presentation/widgets/forms/stock_watcher_form.dart';
import 'package:flare_app/features/watchers/presentation/widgets/forms/real_estate_watcher_form.dart';
import 'package:flare_app/features/watchers/presentation/widgets/forms/sports_watcher_form.dart';

import 'package:flare_app/core/widgets/success_overlay.dart';
import 'package:flare_app/core/widgets/top_snackbar.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class CreateWatcherScreen extends StatefulWidget {
  final Map<String, dynamic>? templateData;
  const CreateWatcherScreen({super.key, this.templateData});

  @override
  State<CreateWatcherScreen> createState() => _CreateWatcherScreenState();
}

class _CreateWatcherScreenState extends State<CreateWatcherScreen> {
  String _selectedType = 'flight';
  Map<String, dynamic> _formData = {};

  int _intervalMinutes = 360;
  double _weeklyBudget = 0.50;
  String _priority = 'medium';

  @override
  void initState() {
    super.initState();
    if (widget.templateData != null) {
      _selectedType = widget.templateData!['type'] ?? 'flight';
      _formData = {
        'name': widget.templateData!['title'],
        'parameters': widget.templateData!['params'] ?? {},
      };
      _intervalMinutes = _types.firstWhere((t) => t['id'] == _selectedType)['interval'];
    }
  }

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _voiceText = '';

  final List<Map<String, dynamic>> _types = [
    {'id': 'flight', 'name': 'Flights', 'emoji': '✈️', 'desc': 'Track airline prices', 'cost': '~\$0.50/wk', 'interval': 360},
    {'id': 'crypto', 'name': 'Crypto', 'emoji': '💰', 'desc': 'Monitor coin prices', 'cost': '~\$0.30/wk', 'interval': 60},
    {'id': 'news', 'name': 'News', 'emoji': '📰', 'desc': 'Watch for articles', 'cost': '~\$0.25/wk', 'interval': 720},
    {'id': 'product', 'name': 'Products', 'emoji': '🛍️', 'desc': 'Track product prices', 'cost': '~\$0.20/wk', 'interval': 720},
    {'id': 'job', 'name': 'Jobs', 'emoji': '💼', 'desc': 'Find opportunities', 'cost': '~\$0.15/wk', 'interval': 1440},
    {'id': 'stock', 'name': 'Stocks', 'emoji': '📊', 'desc': 'Watch stock prices', 'cost': '~\$0.20/wk', 'interval': 60},
    {'id': 'realestate', 'name': 'Real Estate', 'emoji': '🏠', 'desc': 'Monitor listings', 'cost': '~\$0.40/wk', 'interval': 1440},
    {'id': 'events', 'name': 'Events', 'emoji': '🎫', 'desc': 'Tickets & price drops', 'cost': '~\$0.25/wk', 'interval': 360},
  ];

  void _onTypeSelect(String typeId) {
    if (typeId == 'events') {
      context.push('/events');
      return;
    }
    setState(() {
      _selectedType = typeId;
      _formData = {};
      _intervalMinutes = _types.firstWhere((t) => t['id'] == typeId)['interval'];
    });
  }

  void _onFormChanged(Map<String, dynamic> data) {
    _formData = data;
  }

  Future<void> _startListening() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) {
        setState(() {
           _voiceText = val.recognizedWords;
           if (val.finalResult) {
             _isListening = false;
             _parseVoiceInput(_voiceText);
           }
        });
      });
    }
  }

  void _parseVoiceInput(String text) {
    final lower = text.toLowerCase();
    String type = _selectedType;
    Map<String, dynamic> params = {};

    if (lower.contains('flight') || lower.contains('fly')) {
      type = 'flight';
      if (lower.contains('tokyo')) params['destination'] = 'Tokyo (NRT)';
      if (lower.contains('800')) params['price_below'] = 800;
    } else if (lower.contains('bitcoin') || lower.contains('crypto')) {
      type = 'crypto';
      params['coins'] = ['BTC'];
      if (lower.contains('percent') || lower.contains('change')) params['change_24h_percent'] = 5;
    } else if (lower.contains('apple') || lower.contains('stock')) {
      type = 'stock';
      params['symbols'] = ['AAPL'];
    } else if (lower.contains('news') || lower.contains('article')) {
      type = 'news';
      params['keywords'] = ['Stellar', 'Blockchain'];
    } else if (lower.contains('job') || lower.contains('hiring')) {
      type = 'job';
      params['keywords'] = ['Flutter Developer'];
      params['is_remote'] = true;
    } else if (lower.contains('price') || lower.contains('buy')) {
      type = 'product';
      params['product_name'] = 'Sony WH-1000XM5';
      params['price_below'] = 300.0;
    } else if (lower.contains('house') || lower.contains('apartment') || lower.contains('rent')) {
      type = 'realestate';
      params['city'] = 'Austin, TX';
      params['mode'] = lower.contains('rent') ? 'rental' : 'purchase';
    } else if (lower.contains('game') || lower.contains('match') || lower.contains('ticket')) {
      type = 'sports';
      params['team'] = 'Warriors';
      params['price_max'] = 150.0;
    }

    setState(() {
      _selectedType = type;
      _formData = {
        'name': 'Voice Agent: $text',
        'parameters': params,
        'alert_conditions': {},
      };
    });

    TopSnackbar.showSuccess(context, 'Flare understood: $text');

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _launchWatcher();
    });
  }

  void _launchWatcher() {
    if (_formData.isEmpty || _formData['name'] == null || _formData['name'].toString().trim().isEmpty) {
      TopSnackbar.showError(context, 'Please fill out the required watcher details.');
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final finalData = {
      ..._formData,
      'user_id': authState.user.userId,
      'type': _selectedType,
      'check_interval_minutes': _intervalMinutes,
      'weekly_budget_usdc': _weeklyBudget,
      'priority': _priority,
      'status': 'active',
    };

    context.read<WatchersBloc>().add(CreateWatcher(finalData));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WatchersBloc, WatchersState>(
      listener: (context, state) {
        if (state is WatcherActionSuccess) {
          SuccessOverlay.show(context, message: 'Deployed! 🚀', subMessage: 'Your ${_selectedType.toUpperCase()} agent is now hunting.');
          Future.delayed(const Duration(milliseconds: 2000), () => context.pop());
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Create Watcher', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : AppTheme.primary),
              onPressed: _isListening ? () => _speech.stop() : _startListening,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            if (_isListening)
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.primary.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(Icons.graphic_eq, color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_voiceText.isEmpty ? 'Listening...' : _voiceText, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Step 1: Choose Type', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 16),
                    _buildTypeGrid(),
                    const SizedBox(height: 32),
                    const Text('Step 2: Configure', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 16),
                    _buildConfigurationForm(),
                    const SizedBox(height: 32),
                    _buildAdvancedSettings(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: _types.length,
      itemBuilder: (context, index) {
        final type = _types[index];
        final isSelected = _selectedType == type['id'];
        return InkWell(
          onTap: () => _onTypeSelect(type['id']),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? AppTheme.primary : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(type['emoji'], style: const TextStyle(fontSize: 24)),
                    if (isSelected) const Icon(Icons.check_circle, color: Colors.white, size: 16),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isSelected ? Colors.white : AppTheme.textPrimary)),
                    Text(type['desc'], style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : AppTheme.textSecondary)),
                  ],
                ),
                Text(type['cost'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.primary)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfigurationForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(28)),
      child: () {
        switch (_selectedType) {
          case 'flight': return FlightWatcherForm(onChanged: _onFormChanged, key: ValueKey('flight_$_voiceText'), initialData: _formData['parameters']);
          case 'crypto': return CryptoWatcherForm(onChanged: _onFormChanged, key: ValueKey('crypto_$_voiceText'), initialData: _formData['parameters']);
          case 'news': return NewsWatcherForm(onChanged: _onFormChanged, key: ValueKey('news_$_voiceText'), initialData: _formData['parameters']);
          case 'product': return ProductWatcherForm(onChanged: _onFormChanged, key: ValueKey('product_$_voiceText'), initialData: _formData['parameters']);
          case 'job': return JobWatcherForm(onChanged: _onFormChanged, key: ValueKey('job_$_voiceText'), initialData: _formData['parameters']);
          case 'stock': return StockWatcherForm(onChanged: _onFormChanged, key: ValueKey('stock_$_voiceText'), initialData: _formData['parameters']);
          case 'realestate': return RealEstateWatcherForm(onChanged: _onFormChanged, key: ValueKey('re_$_voiceText'), initialData: _formData['parameters']);
          case 'sports': return SportsWatcherForm(onChanged: _onFormChanged, key: ValueKey('sports_$_voiceText'), initialData: _formData['parameters']);
          default: return const SizedBox.shrink();
        }
      }(),
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Schedule & Budget', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Check Interval', style: TextStyle(fontWeight: FontWeight.bold)),
                   Text('Every ${_intervalMinutes < 60 ? "$_intervalMinutes min" : "${_intervalMinutes ~/ 60} hours"}'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Weekly Budget', style: TextStyle(fontWeight: FontWeight.bold)),
                   Text('\$${_weeklyBudget.toStringAsFixed(2)} USDC'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(color: AppTheme.surface, border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05)))),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _launchWatcher,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          child: const Text('Deploy Flare Agent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }
}
