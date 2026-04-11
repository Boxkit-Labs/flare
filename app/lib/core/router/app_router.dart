import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flare_app/features/auth/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:flare_app/features/home/presentation/screens/home_screen.dart';
import 'package:flare_app/features/watchers/presentation/screens/watchers_list_screen.dart';
import 'package:flare_app/features/watchers/presentation/screens/create_watcher_screen.dart';
import 'package:flare_app/features/watchers/presentation/screens/watcher_detail_screen.dart';
import 'package:flare_app/features/watchers/presentation/screens/edit_watcher_screen.dart';
import 'package:flare_app/features/findings/presentation/screens/findings_list_screen.dart';
import 'package:flare_app/features/findings/presentation/screens/finding_detail_screen.dart';
import 'package:flare_app/features/briefing/presentation/screens/briefing_screen.dart';
import 'package:flare_app/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:flare_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:flare_app/features/watchers/presentation/screens/watcher_templates_screen.dart';
import 'package:flare_app/features/wallet/presentation/screens/payment_stream_screen.dart';
import 'package:flare_app/features/wallet/presentation/screens/stellar_proof_screen.dart';
import 'package:flare_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:flare_app/features/home/presentation/screens/shell_screen.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static GoRouter? _router;
  static GoRouter get router => _router!;

  /// Reset the router (call before re-init on hot restart)
  static void reset() {
    _router?.dispose();
    _router = null;
  }

  static void init(AuthBloc authBloc) {
    // Dispose any previous router to avoid stale listeners
    if (_router != null) {
      _router!.dispose();
      _router = null;
    }

    _router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/',
      refreshListenable: _AuthRefreshListenable(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final goingToOnboarding = state.matchedLocation == '/onboarding';

        // Still loading or not yet determined — send to onboarding
        if (authState is AuthInitial || authState is AuthLoading) {
          return goingToOnboarding ? null : '/onboarding';
        }

        if (authState is AuthUnauthenticated) {
          return goingToOnboarding ? null : '/onboarding';
        }
        
        if (authState is AuthAuthenticated && goingToOnboarding) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/watchers/create',
          name: 'createWatcher',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: CreateWatcherScreen(templateData: state.extra as Map<String, dynamic>?),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart)),
                child: child,
              );
            },
          ),
        ),
        GoRoute(
          path: '/watchers/templates',
          name: 'watcherTemplates',
          builder: (context, state) => const WatcherTemplatesScreen(),
        ),
        GoRoute(
          path: '/payment-stream',
          name: 'paymentStream',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const PaymentStreamScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/wallet/proof',
          name: 'stellarProof',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const StellarProofScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
                child: child,
              );
            },
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => ShellScreen(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  name: 'home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/watchers',
                  name: 'watchers',
                  builder: (context, state) => const WatchersListScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      name: 'watcherDetail',
                      builder: (context, state) => WatcherDetailScreen(watcherId: state.pathParameters['id']!),
                    ),
                    GoRoute(
                      path: ':id/edit',
                      name: 'editWatcher',
                      builder: (context, state) => EditWatcherScreen(watcherId: state.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/findings',
                  name: 'findings',
                  builder: (context, state) => const FindingsListScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      name: 'findingDetail',
                      builder: (context, state) => FindingDetailScreen(findingId: state.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/briefing',
                  name: 'briefing',
                  builder: (context, state) => const BriefingScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/wallet',
                  name: 'wallet',
                  builder: (context, state) => const WalletScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Stream stream) {
    stream.listen((_) => notifyListeners());
  }
}
