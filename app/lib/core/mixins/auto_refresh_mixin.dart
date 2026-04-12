import 'dart:async';
import 'package:flutter/material.dart';

mixin AutoRefreshMixin<T extends StatefulWidget> on State<T> {
  Timer? _refreshTimer;

  void startAutoRefresh(Duration interval, VoidCallback onRefresh) {
    stopAutoRefresh();
    _refreshTimer = Timer.periodic(interval, (timer) {
      if (mounted) {
        onRefresh();
      }
    });
  }

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
