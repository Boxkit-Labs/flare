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
  int _lastKnownUnreadCount = 0;
  OverlayEntry? _currentBanner;

  String _getEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'flights': return '✈️';
      case 'crypto': return '💰';
      case 'news': return '📰';
      case 'products': return '🛍️';
      case 'jobs': return '💼';
      default: return '👻';
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
          AppRouter.router.push('/findings/$findingId');
        },
      ),
    );
    Overlay.of(context).insert(_currentBanner!);
    Future.delayed(const Duration(seconds: 5), () {
      if (_currentBanner != null) {
        _currentBanner?.remove();
        _currentBanner = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FindingsBloc, FindingsState>(
      listener: (context, state) {
        if (state is FindingsLoaded && state.findings.isNotEmpty) {
           if (state.unreadCount > _lastKnownUnreadCount) {
             final latest = state.findings.first;
             _showNotification(latest.headline, _getEmoji(latest.type), latest.findingId);
           }
           _lastKnownUnreadCount = state.unreadCount;
        }
      },
      child: MaterialApp.router(
        title: 'Flare',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
        scaffoldMessengerKey: AppRouter.scaffoldMessengerKey,
      ),
    );
  }
}
