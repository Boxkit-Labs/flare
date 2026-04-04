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

class CreateWatcherScreen extends StatefulWidget {
  const CreateWatcherScreen({super.key});

  @override
  State<CreateWatcherScreen> createState() => _CreateWatcherScreenState();
}

class _CreateWatcherScreenState extends State<CreateWatcherScreen> {
  int _currentStep = 0;
  String? _selectedType;
  Map<String, dynamic> _formData = {};
  
  // Step 3 settings
  int _intervalMinutes = 720; // 12 hours default
  double _weeklyBudget = 0.50;
  String _priority = 'medium';

  final List<Map<String, dynamic>> _types = [
    {
      'id': 'flight',
      'name': 'Flights',
      'emoji': '✈️',
      'desc': 'Track flight prices',
      'cost': '~\$0.50/week',
      'rec_interval': 360, // 6h
    },
    {
      'id': 'crypto',
      'name': 'Crypto',
      'emoji': '💰',
      'desc': 'Monitor coin prices',
      'cost': '~\$0.30/week',
      'rec_interval': 60, // 1h
    },
    {
      'id': 'news',
      'name': 'News',
      'emoji': '📰',
      'desc': 'Watch for articles',
      'cost': '~\$0.25/week',
      'rec_interval': 720, // 12h
    },
    {
      'id': 'product',
      'name': 'Products',
      'emoji': '🛍️',
      'desc': 'Track product prices',
      'cost': '~\$0.20/week',
      'rec_interval': 720, // 12h
    },
    {
      'id': 'job',
      'name': 'Jobs',
      'emoji': '💼',
      'desc': 'Find new opportunities',
      'cost': '~\$0.15/week',
      'rec_interval': 1440, // 24h
    },
  ];

  void _onStep1Select(String typeId) {
    setState(() {
      _selectedType = typeId;
      _currentStep = 1;
      _intervalMinutes = _types.firstWhere((t) => t['id'] == typeId)['rec_interval'];
    });
  }

  void _onFormChanged(Map<String, dynamic> data) {
    _formData = data;
  }

  void _launchWatcher() {
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
            subMessage: 'Your ${_selectedType?.toUpperCase()} agent is now hunting.'
          );
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (context.mounted) {
              context.goNamed('watchers');
            }
          });
        } else if (state is WatchersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Watcher'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildCurrentStep(),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          return Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primary : AppTheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: isActive ? AppTheme.primary : Colors.grey[700]!),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (index < 2)
                Container(
                  width: 40,
                  height: 2,
                  color: index < _currentStep ? AppTheme.primary : Colors.grey[800],
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildTypeSelection();
      case 1:
        return _buildConfiguration();
      case 2:
        return _buildScheduleAndReview();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What should we watch?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select the type of information agent you want to deploy.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _types.length,
          itemBuilder: (context, index) {
            final type = _types[index];
            final isSelected = _selectedType == type['id'];
            return InkWell(
              onTap: () => _onStep1Select(type['id']),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(type['emoji'], style: const TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text(
                      type['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type['desc'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    const Spacer(),
                    Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(
                         color: Colors.black.withValues(alpha: 0.3),
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: Text(
                        type['cost'],
                        style: const TextStyle(fontSize: 10, color: AppTheme.secondary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildConfiguration() {
    switch (_selectedType) {
      case 'flight':
        return FlightWatcherForm(onChanged: _onFormChanged);
      case 'crypto':
        return CryptoWatcherForm(onChanged: _onFormChanged);
      case 'news':
        return NewsWatcherForm(onChanged: _onFormChanged);
      case 'product':
        return ProductWatcherForm(onChanged: _onFormChanged);
      case 'job':
        return JobWatcherForm(onChanged: _onFormChanged);
      default:
        return const Center(child: Text('Select a type first'));
    }
  }

  Widget _buildScheduleAndReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        const Text('Check Frequency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        _buildFrequencyDropdown(),
        const SizedBox(height: 24),
        
        const Text('Weekly Budget', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('\$${_weeklyBudget.toStringAsFixed(2)} USDC', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary)),
            Text('~${(168 * 60 / _intervalMinutes).floor()} checks/week', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        Slider(
          value: _weeklyBudget,
          min: 0.10,
          max: 2.00,
          divisions: 38,
          label: '\$${_weeklyBudget.toStringAsFixed(2)}',
          activeColor: AppTheme.secondary,
          onChanged: (val) => setState(() => _weeklyBudget = val),
        ),
        
        const SizedBox(height: 24),
        const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
             ButtonSegment(value: 'low', label: Text('Low')),
             ButtonSegment(value: 'medium', label: Text('Medium')),
             ButtonSegment(value: 'high', label: Text('High')),
          ],
          selected: {_priority},
          onSelectionChanged: (val) => setState(() => _priority = val.first),
        ),
        const SizedBox(height: 8),
        const Text(
          'High priority alerts bypass Do Not Disturb settings.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
        ),

        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        _buildReviewSummary(),
      ],
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
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _intervalMinutes,
          isExpanded: true,
          dropdownColor: AppTheme.surface,
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

  Widget _buildReviewSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ready to deploy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildReviewRow('Name', _formData['name'] ?? 'Untitled'),
          _buildReviewRow('Type', _selectedType?.toUpperCase() ?? 'None'),
          _buildReviewRow('Check Rate', 'Every ${_intervalMinutes < 60 ? '$_intervalMinutes min' : '${(_intervalMinutes / 60).floor()}h'}'),
          _buildReviewRow('Budget', '\$${_weeklyBudget.toStringAsFixed(2)} USDC / week'),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_currentStep == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: Colors.grey[900]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
               onPressed: () => setState(() => _currentStep--),
               style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
               child: const Text('Back'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: BlocBuilder<WatchersBloc, WatchersState>(
              builder: (context, state) {
                final isLoading = state is WatchersLoading;
                return ElevatedButton(
                  onPressed: _currentStep == 2 
                      ? (isLoading ? null : _launchWatcher)
                      : () => setState(() => _currentStep++),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentStep == 2 ? AppTheme.primary : AppTheme.surface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_currentStep == 2 ? 'Launch Watcher 🚀' : 'Continue'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
