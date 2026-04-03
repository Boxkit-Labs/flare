import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_app/core/mixins/auto_refresh_mixin.dart';
import 'package:ghost_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ghost_app/features/home/presentation/screens/home_content.dart';
import 'package:ghost_app/features/watchers/presentation/bloc/watchers_bloc.dart';
import 'package:ghost_app/features/watchers/presentation/bloc/watchers_event.dart';
import 'package:ghost_app/features/findings/presentation/bloc/findings_bloc.dart';
import 'package:ghost_app/features/findings/presentation/bloc/findings_event.dart';
import 'package:ghost_app/features/briefing/presentation/bloc/briefing_bloc.dart';
import 'package:ghost_app/features/briefing/presentation/bloc/briefing_event.dart';
import 'package:ghost_app/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:ghost_app/features/wallet/presentation/bloc/wallet_event.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutoRefreshMixin {
  @override
  void initState() {
    super.initState();
    _refreshData();
    startAutoRefresh(const Duration(seconds: 30), _refreshData);
  }

  void _refreshData() {
    final authState = context.read<AuthBloc>().state;
    // Cast to dynamic to access user property from AuthAuthenticated state
    try {
      final userId = (authState as dynamic).user.userId;
      context.read<WatchersBloc>().add(LoadWatchers(userId));
      context.read<FindingsBloc>().add(LoadFindings(userId));
      context.read<WalletBloc>().add(LoadWallet(userId));
      context.read<BriefingBloc>().add(LoadTodayBriefing(userId));
    } catch (_) {
      // Not authenticated or user not available
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _refreshData();
            // Wait for at least one bloc to finish or a small delay
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: const HomeContent(),
        ),
      ),
    );
  }
}
