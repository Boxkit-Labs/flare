import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_state.dart';
import 'package:flare_app/injection_container.dart';
import 'pages/welcome_page.dart';
import 'pages/how_it_works_page.dart';
import 'pages/wallet_setup_page.dart';
import 'pages/notifications_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<OnboardingBloc>(),
      child: BlocListener<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingSuccess) {
            context.read<AuthBloc>().add(UserRegistered(state.user));
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.background,
          body: Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                   WelcomePage(onNext: _nextPage),
                   HowItWorksPage(onNext: _nextPage, onBack: _previousPage),
                   WalletSetupPage(onNext: _nextPage, onBack: _previousPage),
                   NotificationsPage(onBack: _previousPage),
                ],
              ),
              
              // Top Progress Line
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                     color: Colors.black.withValues(alpha: 0.05),
                     borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutQuart,
                        width: (MediaQuery.of(context).size.width - 40) * ((_currentPage + 1) / 4),
                        decoration: BoxDecoration(
                           gradient: AppTheme.primaryGradient,
                           borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Indicators
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) {
                      final isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: isActive
                              ? AppTheme.primary
                              : Colors.black.withValues(alpha: 0.1),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

