import 'dart:async';
import 'package:flutter/material.dart';

/// Mixin to handle periodic auto-refreshing of data in [StatefulWidget] states.
mixin AutoRefreshMixin<T extends StatefulWidget> on State<T> {
  Timer? _refreshTimer;

  /// Starts the auto-refresh timer.
  /// 
  /// [interval] is the duration between refreshes.
  /// [onRefresh] is the callback to execute every [interval].
  void startAutoRefresh(Duration interval, VoidCallback onRefresh) {
    stopAutoRefresh(); // Ensure no duplicate timers
    _refreshTimer = Timer.periodic(interval, (timer) {
      if (mounted) {
        onRefresh();
      }
    });
  }

  /// Stops the current auto-refresh timer if any.
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
