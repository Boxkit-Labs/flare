import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ghost_app/app.dart';
import 'package:ghost_app/injection_container.dart' as di;
import 'package:ghost_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ghost_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:ghost_app/services/notification_service.dart';

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

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>()..add(AppStarted()),
        ),
      ],
      child: const GhostApp(),
    ),
  );
}
