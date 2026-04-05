import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_event.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_state.dart';
import 'package:flare_app/core/widgets/top_snackbar.dart';

class WalletSetupPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const WalletSetupPage({super.key, required this.onNext, required this.onBack});

  @override
  State<WalletSetupPage> createState() => _WalletSetupPageState();
}

class _WalletSetupPageState extends State<WalletSetupPage> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      // Start registration on enter
      context.read<OnboardingBloc>().add(const StartRegistration('DEVICE_ID_PLACEHOLDER'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingWalletCreated) {
          // Fund immediately after creation
          context.read<OnboardingBloc>().add(FundWallet(state.user.userId));
        }
      },
      builder: (context, state) {
        final isFunded = state is OnboardingWalletFunded || state is OnboardingWatcherCreated || state is OnboardingSuccess;
        final isLoading = state is OnboardingGeneratingWallet || state is OnboardingFundingWallet;

        // Extract user from state if possible to show public key
        String? publicKey;
        if (state is OnboardingWalletCreated) publicKey = state.user.stellarPublicKey;
        if (state is OnboardingSuccess) publicKey = state.user.stellarPublicKey;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Wallet Setup',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 10),
              Text(
                'Setting up your agent\'s wallet on Stellar',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 40),
              _buildStep('Creating Stellar wallet...', 
                state is! OnboardingInitial && state is! OnboardingGeneratingWallet),
              const SizedBox(height: 12),
              _buildStep('Funding with testnet XLM...', 
                isFunded || (state is OnboardingFundingWallet && false /* for animation */)), // Simple logic
              const SizedBox(height: 12),
              _buildStep('Adding USDC...', isFunded),
              const SizedBox(height: 12),
              _buildStep('Loading test funds...', isFunded),
              
              if (isFunded) ...[
                const SizedBox(height: 40),
                Card(
                  child: ListTile(
                    title: const Text('Public Key',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    subtitle: Text(publicKey ?? 'GXXXXXXXXXXXXXXXXXXXXXXXXX',
                        overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: publicKey ?? ''));
                        TopSnackbar.showSuccess(context, 'Address copied');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${(state is OnboardingWalletFunded ? state.balance : 10.0).toStringAsFixed(2)} USDC ready to go',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
              
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: isLoading ? null : widget.onBack,
                    child: const Text('Back',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  ElevatedButton(
                    onPressed: isFunded ? widget.onNext : null,
                    child: isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Next'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStep(String label, bool isDone) {
    return Row(
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.circle_outlined,
          color: isDone ? AppTheme.secondary : AppTheme.surface,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isDone ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
