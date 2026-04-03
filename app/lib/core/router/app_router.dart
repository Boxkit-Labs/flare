import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_app/core/util/placeholder_screen.dart';
import 'package:ghost_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ghost_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:ghost_app/features/auth/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:ghost_app/features/home/presentation/screens/home_screen.dart';
import 'package:ghost_app/features/watchers/presentation/screens/watchers_list_screen.dart';
import 'package:ghost_app/features/watchers/presentation/screens/create_watcher_screen.dart';
import 'package:ghost_app/features/watchers/presentation/screens/watcher_detail_screen.dart';
import 'package:ghost_app/features/home/presentation/screens/shell_screen.dart';

class AppRouter {
  AppRouter._();

  static late GoRouter router;

  static void init(AuthBloc authBloc) {
    router = GoRouter(
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
          builder: (context, state) => const PlaceholderScreen(title: 'Settings'),
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
          path: '/findings/:id',
          name: 'findingDetail',
          builder: (context, state) => PlaceholderScreen(
            title: 'Finding ${state.pathParameters['id']}',
          ),
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
              builder: (context, state) => const PlaceholderScreen(title: 'Findings'),
            ),
            GoRoute(
              path: '/briefing',
              name: 'briefing',
              builder: (context, state) => const PlaceholderScreen(title: 'Briefing'),
            ),
            GoRoute(
              path: '/wallet',
              name: 'wallet',
              builder: (context, state) => const PlaceholderScreen(title: 'Wallet'),
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
