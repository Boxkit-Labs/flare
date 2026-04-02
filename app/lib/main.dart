import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ghost_app/app.dart';
import 'package:ghost_app/injection_container.dart' as di;
import 'package:ghost_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ghost_app/features/auth/presentation/bloc/auth_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Dependency Injection
  await di.init();

  // Initialize Hive
  await Hive.initFlutter();

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
