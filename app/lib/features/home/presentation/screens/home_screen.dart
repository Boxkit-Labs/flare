import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/core/mixins/auto_refresh_mixin.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flare_app/features/home/presentation/screens/home_content.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_bloc.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_event.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_bloc.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_event.dart';
import 'package:flare_app/features/briefing/presentation/bloc/briefing_bloc.dart';
import 'package:flare_app/features/briefing/presentation/bloc/briefing_event.dart';
import 'package:flare_app/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flare_app/features/wallet/presentation/bloc/wallet_event.dart';
import 'package:flare_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:flare_app/features/notifications/presentation/bloc/notifications_event.dart';

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
    startAutoRefresh(const Duration(seconds: 120), _refreshData);
  }

  void _refreshData({bool force = false}) {
    if (!mounted) return;
    
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final userId = authState.user.userId;
      final isRefresh = !force;
      context.read<WalletBloc>().add(LoadAllWalletData(userId, isRefresh: isRefresh));
      context.read<WatchersBloc>().add(LoadWatchers(userId, isRefresh: isRefresh));
      context.read<FindingsBloc>().add(LoadFindings(userId, isRefresh: isRefresh));
      context.read<BriefingBloc>().add(LoadTodayBriefing(userId, isRefresh: isRefresh));
      context.read<NotificationsBloc>().add(LoadUnreadCount(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _refreshData(force: true);
            // Wait for at least one bloc to finish or a small delay
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: const HomeContent(),
        ),
      ),
    );
  }
}
