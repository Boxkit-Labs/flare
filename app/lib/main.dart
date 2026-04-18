import 'package:flare_app/features/events/presentation/bloc/event_detail_bloc.dart';
import 'package:flare_app/features/events/presentation/bloc/event_price_history_bloc.dart';
import 'package:flare_app/features/events/presentation/bloc/event_search_bloc.dart';
import 'package:flare_app/features/events/presentation/bloc/event_watch_setup_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flare_app/app.dart';
import 'package:flare_app/core/router/app_router.dart';
import 'package:flare_app/injection_container.dart' as di;
import 'package:flare_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:flare_app/services/notification_service.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_bloc.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_bloc.dart';
import 'package:flare_app/features/briefing/presentation/bloc/briefing_bloc.dart';
import 'package:flare_app/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flare_app/features/notifications/presentation/bloc/notifications_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Dependency Injection
  await di.init();

  // Initialize Push Notifications
  final notificationService = di.sl<NotificationService>();
  await notificationService.init();

  // Initialize Router with the shared AuthBloc singleton
  final authBloc = di.sl<AuthBloc>()..add(AppStarted());
  AppRouter.init(authBloc);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<WatchersBloc>(create: (context) => di.sl<WatchersBloc>()),
        BlocProvider<FindingsBloc>(create: (context) => di.sl<FindingsBloc>()),
        BlocProvider<BriefingBloc>(create: (context) => di.sl<BriefingBloc>()),
        BlocProvider<WalletBloc>(create: (context) => di.sl<WalletBloc>()),
        BlocProvider<NotificationsBloc>(
          create: (context) => di.sl<NotificationsBloc>(),
        ),
        BlocProvider<EventSearchBloc>(
          create: (context) => di.sl<EventSearchBloc>(),
        ),
        BlocProvider<EventDetailBloc>(
          create: (context) => di.sl<EventDetailBloc>(),
        ),
        BlocProvider<EventPriceHistoryBloc>(
          create: (context) => di.sl<EventPriceHistoryBloc>(),
        ),
        BlocProvider<EventWatchSetupBloc>(
          create: (context) => di.sl<EventWatchSetupBloc>(),
        ),
      ],
      child: const FlareApp(),
    ),
  );
}
