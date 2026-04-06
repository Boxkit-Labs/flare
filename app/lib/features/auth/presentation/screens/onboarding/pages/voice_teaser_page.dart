import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_event.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_state.dart';

class VoiceTeaserPage extends StatefulWidget {
  final VoidCallback onBack;
  const VoiceTeaserPage({super.key, required this.onBack});

  @override
  State<VoiceTeaserPage> createState() => _VoiceTeaserPageState();
}

class _VoiceTeaserPageState extends State<VoiceTeaserPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    final apiService = context.read<OnboardingBloc>().apiService;
    if (apiService.userId != null) {
      // Just complete with default (or whatever was set in notifications step)
      context.read<OnboardingBloc>().add(CompleteOnboarding(apiService.userId!, "07:00"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {},
      builder: (context, state) {
        final isLoading = state is OnboardingCompleting;

        return Container(
          color: AppTheme.background,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _pulse,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppTheme.primary.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 10),
                    ],
                    gradient: const RadialGradient(
                      colors: [Colors.white, AppTheme.primary],
                      stops: [0.1, 0.8],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              const Text(
                'Ambient Intelligence',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
              ),
              const SizedBox(height: 16),
              const Text(
                'Flare is learning to speak. Our Voice Intelligence Suite is now processing your active hunts.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w500, height: 1.5),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'STILL IN BETA — DEMO AVAILABLE AT SCREEN 4.5',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.amber, letterSpacing: 1.0),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _finish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'ENTER FLARE INTELLIGENCE',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: isLoading ? null : widget.onBack,
                child: const Text('Back', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }
}
