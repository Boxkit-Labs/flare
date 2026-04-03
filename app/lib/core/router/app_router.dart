import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ghost_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:ghost_app/features/auth/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:ghost_app/features/home/presentation/screens/home_screen.dart';
import 'package:ghost_app/features/watchers/presentation/screens/watchers_list_screen.dart';
import 'package:ghost_app/features/watchers/presentation/screens/create_watcher_screen.dart';
import 'package:ghost_app/features/watchers/presentation/screens/watcher_detail_screen.dart';
import 'package:ghost_app/features/watchers/presentation/screens/edit_watcher_screen.dart';
import 'package:ghost_app/features/findings/presentation/screens/findings_list_screen.dart';
import 'package:ghost_app/features/findings/presentation/screens/finding_detail_screen.dart';
import 'package:ghost_app/features/briefing/presentation/screens/briefing_screen.dart';
import 'package:ghost_app/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:ghost_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:ghost_app/features/home/presentation/screens/shell_screen.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static late GoRouter router;

  static void init(AuthBloc authBloc) {
    router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/',
      refreshListenable: _AuthRefreshListenable(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final goingToOnboarding = state.matchedLocation == '/onboarding';

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
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/watchers/create',
          name: 'createWatcher',
          builder: (context, state) => const CreateWatcherScreen(),
        ),
        GoRoute(
          path: '/watchers/:id',
          name: 'watcherDetail',
          builder: (context, state) {
             final id = state.pathParameters['id']!;
             return WatcherDetailScreen(watcherId: id);
          },
        ),
        GoRoute(
          path: '/watchers/:id/edit',
          name: 'editWatcher',
          builder: (context, state) {
             final id = state.pathParameters['id']!;
             return EditWatcherScreen(watcherId: id);
          },
        ),
        GoRoute(
          path: '/findings/:id',
          name: 'findingDetail',
          builder: (context, state) {
             final id = state.pathParameters['id']!;
             return FindingDetailScreen(findingId: id);
          },
        ),
        ShellRoute(
          builder: (context, state, child) => ShellScreen(child: child),
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/watchers',
              name: 'watchers',
              builder: (context, state) => const WatchersListScreen(),
            ),
            GoRoute(
              path: '/findings',
              name: 'findings',
              builder: (context, state) => const FindingsListScreen(),
            ),
            GoRoute(
              path: '/briefing',
              name: 'briefing',
              builder: (context, state) => const BriefingScreen(),
            ),
            GoRoute(
              path: '/wallet',
              name: 'wallet',
              builder: (context, state) => const WalletScreen(),
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
