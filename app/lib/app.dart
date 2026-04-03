import 'package:flutter/material.dart';
import 'package:ghost_app/core/theme/app_theme.dart';
import 'package:ghost_app/core/router/app_router.dart';

class GhostApp extends StatelessWidget {
  const GhostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
