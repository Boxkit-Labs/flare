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

  String? _publicKey;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingWalletCreated) {
           _publicKey = state.user.stellarPublicKey;
          // Fund immediately after creation
          context.read<OnboardingBloc>().add(FundWallet(state.user.userId));
        }
        if (state is OnboardingSuccess) {
           _publicKey = state.user.stellarPublicKey;
        }
      },
      builder: (context, state) {
        final isFunded = state is OnboardingWalletFunded || state is OnboardingWatcherCreated || state is OnboardingSuccess;
        final isLoading = state is OnboardingGeneratingWallet || state is OnboardingFundingWallet || state is OnboardingInitial;

        // Extract user from state if possible to show public key
        if (state is OnboardingWalletCreated) _publicKey = state.user.stellarPublicKey;
        if (state is OnboardingSuccess) _publicKey = state.user.stellarPublicKey;
        
        return Container(
          color: AppTheme.background,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Wallet Setup',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Initializing your agent\'s decentralized wallet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),
              
              _buildStepItem(
                'Generating Stellar Keys', 
                state is! OnboardingInitial && state is! OnboardingGeneratingWallet,
                isCurrent: state is OnboardingGeneratingWallet,
              ),
              _buildStepItem(
                'Provisioning Testnet XLM', 
                isFunded,
                isCurrent: state is OnboardingFundingWallet,
              ),
              _buildStepItem(
                'Loading USDC Balance', 
                isFunded,
                isCurrent: state is OnboardingFundingWallet,
              ),
              _buildStepItem(
                'Syncing with Network', 
                isFunded,
                isCurrent: isFunded && state is! OnboardingSuccess,
              ),
              
              if (isFunded) ...[
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                    boxShadow: [
                       BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('PUBLIC KEY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 1.0)),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: _publicKey ?? ''));
                              TopSnackbar.showSuccess(context, 'Address copied!');
                            },
                            child: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _publicKey ?? 'GXXXXXXXXXXXXXXXXXXXXXXXXX',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 32, color: AppTheme.background),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            '${(state is OnboardingWalletFunded ? state.balance : 10.0).toStringAsFixed(2)} USDC AVAILABLE',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: isLoading ? null : widget.onBack,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: isFunded ? AppTheme.primaryGradient : null,
                      color: isFunded ? null : AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isFunded ? [
                        BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                      ] : null,
                    ),
                    child: ElevatedButton(
                      onPressed: isFunded ? widget.onNext : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                        : Text('Next', style: TextStyle(fontWeight: FontWeight.w900, color: isFunded ? Colors.white : AppTheme.textSecondary)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepItem(String label, bool isDone, {bool isCurrent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDone ? Colors.green.withValues(alpha: 0.1) : (isCurrent ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.surface),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isDone 
                ? const Icon(Icons.check_rounded, color: Colors.green, size: 14) 
                : (isCurrent 
                   ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                   : Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.background, shape: BoxShape.circle))),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isCurrent || isDone ? FontWeight.w900 : FontWeight.w500,
              color: isDone ? AppTheme.textPrimary : (isCurrent ? AppTheme.primary : AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

