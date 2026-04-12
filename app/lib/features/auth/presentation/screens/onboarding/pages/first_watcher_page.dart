import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_event.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_state.dart';

class FirstWatcherPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const FirstWatcherPage({super.key, required this.onNext, required this.onBack});

  @override
  State<FirstWatcherPage> createState() => _FirstWatcherPageState();
}

class _FirstWatcherPageState extends State<FirstWatcherPage> {
  String? _selectedType;
  final Map<String, dynamic> _parameters = {};
  final TextEditingController _paramController = TextEditingController();

  void _onTypeSelect(String type) {
    setState(() {
      _selectedType = type;
      _parameters.clear();
      _paramController.clear();
    });
  }

  void _createWatcher() {
    if (_selectedType == null) return;

    final state = context.read<OnboardingBloc>().state;
    String? userId;
    if (state is OnboardingWalletFunded) userId = state.userId;
    if (userId == null) return;

    String backendType = _selectedType!.toLowerCase();
    if (backendType == 'flights') backendType = 'flight';
    if (backendType == 'products') backendType = 'product';
    if (backendType == 'jobs') backendType = 'job';

    context.read<OnboardingBloc>().add(CreateInitialWatcher({
      'user_id': userId,
      'name': 'Initial ${_selectedType!.toUpperCase()} Watcher',
      'type': backendType,
      'parameters': _parameters,
      'alert_conditions': _getAlertConditions(),
      'check_interval_minutes': 60,
      'weekly_budget_usdc': 1.00
    }));
  }

  Map<String, dynamic> _getAlertConditions() {
     switch(_selectedType) {
       case 'Flights': return {'property': 'price', 'operator': '<', 'value': 900};
       case 'Crypto': return {'property': 'priceUsd', 'operator': '>', 'value': 1000};
       case 'News': return {'property': 'matches', 'operator': '>', 'value': 0};
       default: return {'property': 'status', 'operator': '==', 'value': 'ready'};
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'First Watcher',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 10),
              Text(
                'Tell Flare what to keep an eye on',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 30),
              if (_selectedType == null) ...[
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    shrinkWrap: true,
                    children: [
                      _buildTypeCard('✈️ Flights', 'Flights'),
                      _buildTypeCard('💰 Crypto', 'Crypto'),
                      _buildTypeCard('📰 News', 'News'),
                      _buildTypeCard('🛍️ Products', 'Products'),
                      _buildTypeCard('💼 Jobs', 'Jobs'),
                    ],
                  ),
                ),
              ] else ...[
                _buildSimpleForm(),
                const Spacer(),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: isLoading ? null : (_selectedType == null ? widget.onBack : () => setState(() => _selectedType = null)),
                    child: const Text('Back', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  if (_selectedType != null)
                    ElevatedButton(
                      onPressed: isLoading ? null : _createWatcher,
                      child: isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Create & Launch'),
                    ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeCard(String label, String value) {
    return InkWell(
      onTap: () => _onTypeSelect(value),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSimpleForm() {
    String hint = "";
    if (_selectedType == 'Flights') hint = "Destination (e.g. CDG)";
    if (_selectedType == 'Crypto') hint = "Coin ID (e.g. ethereum)";
    if (_selectedType == 'News') hint = "Keyword (e.g. stellar)";
    if (_selectedType == 'Products') hint = "Product (e.g. iPhone)";
    if (_selectedType == 'Jobs') hint = "Role (e.g. Developer)";

    return Column(
      children: [
        Text('Configure your $_selectedType Watcher', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(
          controller: _paramController,
          decoration: InputDecoration(
            hintText: hint,
          ),
          onChanged: (val) {
             if (_selectedType == 'Flights') _parameters['destination'] = val;
             if (_selectedType == 'Crypto') _parameters['coin_id'] = val;
             if (_selectedType == 'News') _parameters['keywords'] = [val];
             if (_selectedType == 'Products') _parameters['title'] = val;
             if (_selectedType == 'Jobs') _parameters['keywords'] = [val];
          },
        ),
      ],
    );
  }
}
