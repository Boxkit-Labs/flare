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
import 'package:flare_app/features/events/presentation/pages/event_discovery_page.dart';
import 'package:flare_app/features/events/presentation/pages/event_detail_page.dart';
import 'package:flare_app/features/events/domain/entities/event_entity.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static GoRouter? _router;
  static GoRouter get router => _router!;

  static void reset() {
    _router?.dispose();
    _router = null;
  }

  static void init(AuthBloc authBloc) {
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
        GoRoute(
          path: '/watchers/:id',
          name: 'watcherDetail',
          parentNavigatorKey: navigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: WatcherDetailScreen(watcherId: state.pathParameters['id']!),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/watchers/:id/edit',
          name: 'editWatcher',
          parentNavigatorKey: navigatorKey,
          builder: (context, state) => EditWatcherScreen(watcherId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/findings/:id',
          name: 'findingDetail',
          parentNavigatorKey: navigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: FindingDetailScreen(findingId: state.pathParameters['id']!),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/events/discovery',
          name: 'eventDiscovery',
          builder: (context, state) => const EventDiscoveryPage(),
        ),
        GoRoute(
          path: '/events/detail/:platform/:id',
          name: 'eventDetail',
          builder: (context, state) => EventDetailPage(
            platform: state.pathParameters['platform']!,
            externalId: state.pathParameters['id']!,
            initialEvent: state.extra as EventEntity?,
          ),
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
