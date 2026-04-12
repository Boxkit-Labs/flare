import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/router/app_router.dart';
import 'package:flare_app/core/widgets/notification_banner.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_bloc.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_state.dart';

class FlareApp extends StatefulWidget {
  const FlareApp({super.key});

  @override
  State<FlareApp> createState() => _FlareAppState();
}

class _FlareAppState extends State<FlareApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      scaffoldMessengerKey: AppRouter.scaffoldMessengerKey,
      builder: (context, child) {
        return NotificationOverlayManager(child: child!);
      },
    );
  }
}

class NotificationOverlayManager extends StatefulWidget {
  final Widget child;
  const NotificationOverlayManager({super.key, required this.child});

  @override
  State<NotificationOverlayManager> createState() =>
      _NotificationOverlayManagerState();
}

class _NotificationOverlayManagerState
    extends State<NotificationOverlayManager> {
  OverlayEntry? _currentBanner;

  String _getEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'flights':
        return '✈️';
      case 'crypto':
        return '💰';
      case 'news':
        return '📰';
      case 'products':
        return '🛍️';
      case 'jobs':
        return '💼';
      default:
        return '👻';
    }
  }

  void _showNotification(String message, String emoji, String findingId) {
    if (_currentBanner != null) {
      _currentBanner?.remove();
    }
    _currentBanner = OverlayEntry(
      builder: (context) => NotificationBanner(
        emoji: emoji,
        headline: message,
        onTap: () {
          _currentBanner?.remove();
          _currentBanner = null;
          AppRouter.router.go('/findings/$findingId');
        },
      ),
    );
    Overlay.of(context).insert(_currentBanner!);
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _currentBanner != null) {
        _currentBanner?.remove();
        _currentBanner = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FindingsBloc, FindingsState>(
      listenWhen: (previous, current) {
        if (current is! FindingsLoaded) return false;
        if (previous is! FindingsLoaded) return current.unreadCount > 0;
        return current.unreadCount > previous.unreadCount;
      },
      listener: (context, state) {
        if (state is FindingsLoaded && state.findings.isNotEmpty) {
          final latest = state.findings.first;
          _showNotification(
            latest.headline,
            _getEmoji(latest.type),
            latest.findingId,
          );
        }
      },
      child: widget.child,
    );
  }
}
