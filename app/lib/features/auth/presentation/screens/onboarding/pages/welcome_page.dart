import 'package:flutter/material.dart';
import 'package:flare_app/core/theme/app_theme.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const WelcomePage({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      color: AppTheme.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                 BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 40, offset: const Offset(0, 10)),
              ],
            ),
            child: const Center(
              child: Text(
                '👻',
                style: TextStyle(fontSize: 64),
              ),
            ),
          ),
          const SizedBox(height: 48),
          const Text(
            'Flare',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your agents work while you sleep. Automated signals, delivered daily.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 80),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Get Started', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

