import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/core/theme/app_theme.dart';

/// Navigation shell wrapping the main 5 tabs with a premium glassmorphic bottom bar.
class ShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _buildPremiumNavbar(context),
    );
  }

  Widget _buildPremiumNavbar(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 84 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 8,
            top: 12,
            left: 12,
            right: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _buildNavItem(context, 1, Icons.visibility_outlined, Icons.visibility_rounded, 'Agents'),
              _buildNavItem(context, 2, Icons.bolt_outlined, Icons.bolt_rounded, 'Signals'),
              _buildNavItem(context, 3, Icons.wb_sunny_outlined, Icons.wb_sunny_rounded, 'Digest'),
              _buildNavItem(context, 4, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Wallet'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, IconData activeIcon, String label) {
    final isActive = navigationShell.currentIndex == index;
    
    return Expanded(
      child: InkWell(
        onTap: () => _onTap(context, index),
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey('nav_icon_$index\_$isActive'),
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 4 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

