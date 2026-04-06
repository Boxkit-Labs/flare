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

import 'package:flare_app/core/widgets/success_overlay.dart';
import 'package:flare_app/core/widgets/top_snackbar.dart';

class CreateWatcherScreen extends StatefulWidget {
  const CreateWatcherScreen({super.key});

  @override
  State<CreateWatcherScreen> createState() => _CreateWatcherScreenState();
}

class _CreateWatcherScreenState extends State<CreateWatcherScreen> {
  String _selectedType = 'flight'; // Default type
  Map<String, dynamic> _formData = {};
  
  // Settings with defaults
  int _intervalMinutes = 360; 
  double _weeklyBudget = 0.50;
  String _priority = 'medium';

  final List<Map<String, dynamic>> _types = [
    {'id': 'flight', 'name': 'Flights', 'emoji': '✈️', 'rec_interval': 360},
    {'id': 'crypto', 'name': 'Crypto', 'emoji': '💰', 'rec_interval': 60},
    {'id': 'news', 'name': 'News', 'emoji': '📰', 'rec_interval': 720},
    {'id': 'product', 'name': 'Products', 'emoji': '🛍️', 'rec_interval': 720},
    {'id': 'job', 'name': 'Jobs', 'emoji': '💼', 'rec_interval': 1440},
    {'id': 'stock', 'name': 'Stocks', 'emoji': '📊', 'rec_interval': 60},
    {'id': 'realestate', 'name': 'Real Estate', 'emoji': '🏠', 'rec_interval': 1440},
    {'id': 'sports', 'name': 'Sports', 'emoji': '⚽', 'rec_interval': 360},
  ];

  void _onTypeSelect(String typeId) {
    if (_selectedType == typeId) return;
    setState(() {
      _selectedType = typeId;
      _formData = {}; // reset form on switch
      _intervalMinutes = _types.firstWhere((t) => t['id'] == typeId)['rec_interval'];
    });
  }

  void _onFormChanged(Map<String, dynamic> data) {
    _formData = data;
  }

  void _launchWatcher() {
    // validation
    if (_formData.isEmpty || _formData['name'] == null || _formData['name'].toString().trim().isEmpty) {
      TopSnackbar.showError(context, 'Please fill out the required watcher details.');
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final userId = authState.user.userId;
    
    final finalData = {
      ..._formData,
      'user_id': userId,
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
          SuccessOverlay.show(
            context, 
            message: 'Deployed! 🚀', 
            subMessage: 'Your ${_selectedType.toUpperCase()} agent is now hunting.'
          );
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (context.mounted) {
              context.pop();
            }
          });
        } else if (state is WatchersError) {
          TopSnackbar.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Create Watcher'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(color: AppTheme.background),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Agent Type',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      _buildTypeSelector(),
                      
                      const SizedBox(height: 32),
                      const Text(
                        'Configuration',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      _buildConfigurationForm(),

                      const SizedBox(height: 24),
                      _buildAdvancedSettings(),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: _types.map((type) {
          final isSelected = _selectedType == type['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => _onTypeSelect(type['id']),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    Text(type['emoji'], style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      type['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConfigurationForm() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_selectedType),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))
          ],
        ),
        child: () {
          switch (_selectedType) {
            case 'flight':
              return FlightWatcherForm(onChanged: _onFormChanged, key: const ValueKey('flight_form'));
            case 'crypto':
              return CryptoWatcherForm(onChanged: _onFormChanged, key: const ValueKey('crypto_form'));
            case 'news':
              return NewsWatcherForm(onChanged: _onFormChanged, key: const ValueKey('news_form'));
            case 'product':
              return ProductWatcherForm(onChanged: _onFormChanged, key: const ValueKey('product_form'));
            case 'job':
              return JobWatcherForm(onChanged: _onFormChanged, key: const ValueKey('job_form'));
            case 'stock':
            case 'realestate':
            case 'sports':
              return NewsWatcherForm(onChanged: _onFormChanged, key: ValueKey('${_selectedType}_form'));
            default:
              return const SizedBox.shrink();
          }
        }(),
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: const Text('Advanced Schedule & Budget', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: const Text('Frequency and max spending limits', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        tilePadding: EdgeInsets.zero,
        iconColor: AppTheme.primary,
        collapsedIconColor: AppTheme.textSecondary,
        childrenPadding: const EdgeInsets.only(top: 16, bottom: 24),
        children: [
           Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                 BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Check Frequency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                _buildFrequencyDropdown(),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Weekly Budget', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('\$${_weeklyBudget.toStringAsFixed(2)} USDC', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
                  ],
                ),
                Slider(
                  value: _weeklyBudget,
                  min: 0.10,
                  max: 2.00,
                  divisions: 38,
                  activeColor: AppTheme.primary,
                  inactiveColor: AppTheme.primaryLight.withValues(alpha: 0.2),
                  onChanged: (val) => setState(() => _weeklyBudget = val),
                ),
                
                const SizedBox(height: 16),
                const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    selectedBackgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    selectedForegroundColor: AppTheme.primary,
                  ),
                  segments: const [
                     ButtonSegment(value: 'low', label: Text('Low')),
                     ButtonSegment(value: 'medium', label: Text('Medium')),
                     ButtonSegment(value: 'high', label: Text('High')),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (val) => setState(() => _priority = val.first),
                ),
              ],
            ),
           ),
        ],
      ),
    );
  }

  Widget _buildFrequencyDropdown() {
    final Map<String, List<Map<String, dynamic>>> intervals = {
      'flight': [{'l': '6 hours (rec.)', 'v': 360}, {'l': '1 hour', 'v': 60}, {'l': '12 hours', 'v': 720}, {'l': 'Daily', 'v': 1440}],
      'crypto': [{'l': '1 hour (rec.)', 'v': 60}, {'l': '15 min', 'v': 15}, {'l': '6 hours', 'v': 360}, {'l': 'Daily', 'v': 1440}],
      'news': [{'l': '12 hours (rec.)', 'v': 720}, {'l': '6 hours', 'v': 360}, {'l': 'Daily', 'v': 1440}],
      'product': [{'l': '12 hours (rec.)', 'v': 720}, {'l': '6 hours', 'v': 360}, {'l': 'Daily', 'v': 1440}],
      'job': [{'l': 'Daily (rec.)', 'v': 1440}, {'l': '12 hours', 'v': 720}],
    };

    final options = intervals[_selectedType] ?? intervals['news']!;
    
    if (!options.any((opt) => opt['v'] == _intervalMinutes)) {
       _intervalMinutes = options.first['v'];
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _intervalMinutes,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: AppTheme.primary),
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 15),
          items: options.map((opt) {
            return DropdownMenuItem<int>(
              value: opt['v'],
              child: Text(opt['l']),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _intervalMinutes = val);
          },
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: BlocBuilder<WatchersBloc, WatchersState>(
        builder: (context, state) {
          final isLoading = state is WatchersLoading;
          return Container(
             width: double.infinity,
             height: 56,
             decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(30),
               gradient: AppTheme.primaryGradient,
               boxShadow: [
                 BoxShadow(
                   color: AppTheme.primary.withValues(alpha: 0.3),
                   blurRadius: 12,
                   offset: const Offset(0, 4),
                 ),
               ],
             ),
             child: ElevatedButton(
               onPressed: isLoading ? null : _launchWatcher,
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.transparent,
                 shadowColor: Colors.transparent,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
               ),
               child: isLoading 
                   ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                   : const Text('Deploy Watcher', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
             ),
          );
        },
      ),
    );
  }
}

