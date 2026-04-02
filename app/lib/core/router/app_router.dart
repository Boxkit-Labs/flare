import 'package:go_router/go_router.dart';
import 'package:ghost_app/core/util/placeholder_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const PlaceholderScreen(title: 'Home'),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const PlaceholderScreen(title: 'Onboarding'),
      ),
      GoRoute(
        path: '/watchers',
        name: 'watchers',
        builder: (context, state) => const PlaceholderScreen(title: 'Watchers'),
        routes: [
          GoRoute(
            path: 'create',
            name: 'createWatcher',
            builder: (context, state) => const PlaceholderScreen(title: 'Create Watcher'),
          ),
          GoRoute(
            path: ':id',
            name: 'watcherDetail',
            builder: (context, state) => PlaceholderScreen(
              title: 'Watcher ${state.pathParameters['id']}',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/findings',
        name: 'findings',
        builder: (context, state) => const PlaceholderScreen(title: 'Findings'),
        routes: [
          GoRoute(
            path: ':id',
            name: 'findingDetail',
            builder: (context, state) => PlaceholderScreen(
              title: 'Finding ${state.pathParameters['id']}',
            ),
          ),
        ],
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
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const PlaceholderScreen(title: 'Settings'),
      ),
    ],
  );
}
