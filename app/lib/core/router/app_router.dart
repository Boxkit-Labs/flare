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
import 'package:flare_app/features/home/presentation/screens/shell_screen.dart';

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
          path: '/watchers/:id',
          name: 'watcherDetail',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return CustomTransitionPage(
              key: state.pageKey,
              child: WatcherDetailScreen(watcherId: id),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
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
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return CustomTransitionPage(
              key: state.pageKey,
              child: FindingDetailScreen(findingId: id),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          },
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
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/findings',
                  name: 'findings',
                  builder: (context, state) => const FindingsListScreen(),
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
