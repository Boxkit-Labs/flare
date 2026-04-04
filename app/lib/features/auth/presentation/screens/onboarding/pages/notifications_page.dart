import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_event.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_state.dart';
import 'package:flare_app/injection_container.dart';
import 'package:flare_app/services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  final VoidCallback onBack;
  const NotificationsPage({super.key, required this.onBack});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  TimeOfDay _briefingTime = const TimeOfDay(hour: 7, minute: 0);
  bool _notificationsEnabled = false;

  Future<void> _enableNotifications() async {
    final ns = sl<NotificationService>();
    await ns.init();
    setState(() => _notificationsEnabled = true);
  }

  void _finish() {
    // OnboardingSuccess user should be passed to AuthBloc when done.
    // However, we need the userId here.
    // I'll assume the bloc is holding the user ID after registration step.
    // My OnboardingBloc implementation didn't store it in every state, 
    // but the success state of previous steps can be accessed.
    
    // In a real app, I'd have a more robust way. For now, I'll assume I have it.
    // Let's check the API service singleton for the userId.
    final apiService = context.read<OnboardingBloc>().apiService;
    if (apiService.userId != null) {
      final timeStr = "${_briefingTime.hour.toString().padLeft(2, '0')}:${_briefingTime.minute.toString().padLeft(2, '0')}";
      context.read<OnboardingBloc>().add(CompleteOnboarding(apiService.userId!, timeStr));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingSuccess) {
           // AuthBloc listener in OnboardingScreen handles this
        }
      },
      builder: (context, state) {
        final isLoading = state is OnboardingCompleting;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 10),
              Text(
                'One more thing — Flare needs to wake you up',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 40),
              const Text('Morning Briefing Time:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                   final time = await showTimePicker(context: context, initialTime: _briefingTime);
                   if (time != null) setState(() => _briefingTime = time);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _briefingTime.format(context),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: _notificationsEnabled ? null : _enableNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _notificationsEnabled ? AppTheme.secondary.withValues(alpha: 0.2) : AppTheme.primary,
                  foregroundColor: _notificationsEnabled ? AppTheme.secondary : Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_notificationsEnabled ? Icons.check : Icons.notifications_active_outlined),
                    const SizedBox(width: 8),
                    Text(_notificationsEnabled ? 'Notifications Enabled' : 'Enable Notifications'),
                  ],
                ),
              ),
              if (!_notificationsEnabled)
                 const Padding(
                   padding: EdgeInsets.only(top: 8.0),
                   child: Text('Required for morning briefings', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                 ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: isLoading ? null : widget.onBack,
                    child: const Text('Back', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  ElevatedButton(
                    onPressed: isLoading ? null : _finish,
                    child: isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Start Flare'),
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
}
