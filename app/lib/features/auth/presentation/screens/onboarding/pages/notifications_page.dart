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
          color: AppTheme.background,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Flare sends your briefing while you sleep. Decide when you want to wake up to it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),
              
              const Text(
                'DAILY DIGEST DELIVERY', 
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 1.0)
              ),
              const SizedBox(height: 16),
              
              GestureDetector(
                onTap: () async {
                   final time = await showTimePicker(
                     context: context, 
                     initialTime: _briefingTime,
                     builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppTheme.primary,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                     }
                   );
                   if (time != null) setState(() => _briefingTime = time);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                    boxShadow: [
                       BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_filled_rounded, color: AppTheme.primary, size: 24),
                      const SizedBox(width: 16),
                      Text(
                        _briefingTime.format(context),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 60),
              
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _notificationsEnabled ? Colors.green.withValues(alpha: 0.05) : AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _notificationsEnabled ? Colors.green.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.04)),
                ),
                child: InkWell(
                  onTap: _notificationsEnabled ? null : _enableNotifications,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _notificationsEnabled ? Icons.check_circle_rounded : Icons.notifications_active_rounded, 
                          color: _notificationsEnabled ? Colors.green : AppTheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _notificationsEnabled ? 'Notifications Enabled' : 'Enable Notifications',
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 15, 
                            color: _notificationsEnabled ? Colors.green : AppTheme.textPrimary
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
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
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Start Flare', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
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

