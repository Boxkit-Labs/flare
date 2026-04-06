import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_event.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_state.dart';

class TemplateSelectionPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const TemplateSelectionPage({super.key, required this.onNext, required this.onBack});

  @override
  State<TemplateSelectionPage> createState() => _TemplateSelectionPageState();
}

class _TemplateSelectionPageState extends State<TemplateSelectionPage> {
  String? _selectedType;

  final List<Map<String, dynamic>> _templates = [
    {
      'type': 'flight',
      'name': 'Tokyo Flight Finder',
      'icon': '✈️',
      'desc': 'Find alerts for flights to Tokyo under \$800',
      'params': {'destination': 'Tokyo', 'max_price': 800}
    },
    {
      'type': 'crypto',
      'name': 'BTC Whale Watch',
      'icon': '🪙',
      'desc': 'Alert when BTC moves > 5% in 1 hour',
      'params': {'symbol': 'bitcoin', 'threshold': 5}
    },
    {
      'type': 'news',
      'name': 'Tech AI News',
      'icon': '📰',
      'desc': 'Deep dive into "Large Language Models"',
      'params': {'q': 'Large Language Models'}
    },
    {
      'type': 'product',
      'name': 'iPhone Price Drop',
      'icon': '📱',
      'desc': 'Monitor iPhone 15 prices across stores',
      'params': {'query': 'iPhone 15'}
    },
    {
      'type': 'stock',
      'name': 'NVDA Monitor',
      'icon': '📈',
      'desc': 'Alert on Nvidia price spikes',
      'params': {'symbol': 'NVDA'}
    },
    {
      'type': 'job',
      'name': 'Flutter Roles',
      'icon': '💼',
      'desc': 'Find remote Flutter developer jobs',
      'params': {'query': 'Flutter Developer', 'remote': true}
    },
    {
      'type': 'realestate',
      'name': 'Miami Rentals',
      'icon': '🏠',
      'desc': 'Find 2BR apartments in Miami < \$3k',
      'params': {'location': 'Miami', 'max_price': 3000}
    },
    {
      'type': 'sports',
      'name': 'Lakers Tickets',
      'icon': '🏀',
      'desc': 'Alert when Lakers home tickets drop',
      'params': {'team': 'Lakers'}
    },
  ];

  void _selectTemplate(Map<String, dynamic> template) {
    setState(() => _selectedType = template['type']);
    
    final userId = context.read<OnboardingBloc>().apiService.userId;
    if (userId != null) {
      context.read<OnboardingBloc>().add(CreateInitialWatcher({
        'user_id': userId,
        'name': template['name'],
        'type': template['type'],
        'parameters': template['params'],
        'alert_conditions': {'any_change': true},
        'check_interval_minutes': 360,
        'weekly_budget_usdc': 0.50,
        'priority': 'medium',
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingWatcherCreated) {
          widget.onNext();
        }
      },
      builder: (context, state) {
        final isLoading = state is OnboardingCreatingWatcher;

        return Container(
          color: AppTheme.background,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 80),
              const Text(
                'Select Your First Agent',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1.0),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose a template to activate your first background hunt. You can add more later.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final t = _templates[index];
                    final isSelected = _selectedType == t['type'];
                    
                    return InkWell(
                      onTap: isLoading ? null : () => _selectTemplate(t),
                      borderRadius: BorderRadius.circular(24),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : AppTheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : Colors.black.withValues(alpha: 0.05),
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(t['icon'], style: const TextStyle(fontSize: 32)),
                            const SizedBox(height: 12),
                            Text(
                              t['name'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t['desc'],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? Colors.white.withValues(alpha: 0.7) : AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isSelected && isLoading)
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: isLoading ? null : widget.onBack,
                    child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textSecondary)),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : widget.onNext,
                    child: const Text('Skip for now', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }
}
