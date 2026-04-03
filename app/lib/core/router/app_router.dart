import 'package:go_router/go_router.dart';
import 'package:ghost_app/core/util/placeholder_screen.dart';
import 'package:ghost_app/features/home/presentation/screens/shell_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      // Routes outside the shell
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const PlaceholderScreen(title: 'Onboarding'),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const PlaceholderScreen(title: 'Settings'),
      ),
      
      // Feature details (outside shell to hide bottom nav)
      GoRoute(
        path: '/watchers/create',
        name: 'createWatcher',
        builder: (context, state) => const PlaceholderScreen(title: 'Create Watcher'),
      ),
      GoRoute(
        path: '/watchers/:id',
        name: 'watcherDetail',
        builder: (context, state) => PlaceholderScreen(
          title: 'Watcher ${state.pathParameters['id']}',
        ),
      ),
      GoRoute(
        path: '/findings/:id',
        name: 'findingDetail',
        builder: (context, state) => PlaceholderScreen(
          title: 'Finding ${state.pathParameters['id']}',
        ),
      ),

      // Navigation Shell
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const PlaceholderScreen(title: 'Home'),
          ),
          GoRoute(
            path: '/watchers',
            name: 'watchers',
            builder: (context, state) => const PlaceholderScreen(title: 'Watchers'),
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
