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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Dependency Injection
  await di.init();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Push Notifications
  final notificationService = di.sl<NotificationService>();
  await notificationService.init();

  // Initialize Router
  final authBloc = di.sl<AuthBloc>();
  AppRouter.init(authBloc);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>()..add(AppStarted()),
        ),
        BlocProvider<WatchersBloc>(
          create: (context) => di.sl<WatchersBloc>(),
        ),
        BlocProvider<FindingsBloc>(
          create: (context) => di.sl<FindingsBloc>(),
        ),
        BlocProvider<BriefingBloc>(
          create: (context) => di.sl<BriefingBloc>(),
        ),
        BlocProvider<WalletBloc>(
          create: (context) => di.sl<WalletBloc>(),
        ),
      ],
      child: const FlareApp(),
    ),
  );
}
