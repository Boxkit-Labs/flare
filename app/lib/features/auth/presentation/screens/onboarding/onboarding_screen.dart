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
import 'pages/first_watcher_page.dart';
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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
                   FirstWatcherPage(onNext: _nextPage, onBack: _previousPage),
                   NotificationsPage(onBack: _previousPage),
                ],
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / 5,
                  backgroundColor: AppTheme.surface,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 6,
                ),
              ),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? AppTheme.primary
                            : AppTheme.surface,
                      ),
                    ),
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
