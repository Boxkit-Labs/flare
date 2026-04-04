import 'package:flutter/material.dart';
import 'package:flare_app/core/theme/app_theme.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const WelcomePage({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.background,
            AppTheme.surface,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '👻',
            style: TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 20),
          Text(
            'Flare',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  letterSpacing: -1,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your agents work while you sleep',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 60),
          ElevatedButton(
            onPressed: onNext,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Get Started'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
