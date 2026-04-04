import 'package:flutter/material.dart';
import 'package:flare_app/core/theme/app_theme.dart';

class HowItWorksPage extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const HowItWorksPage({super.key, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'How It Works',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 30),
          _buildCard(
            context,
            '📋 Set Watchers',
            'Tell Flare what to monitor: flights, prices, news, jobs, crypto',
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            '🤖 Agents Work',
            'AI agents check data sources and pay per query via Stellar',
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            '🔔 Get Alerts',
            'Wake up to a morning briefing with only what matters',
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onBack,
                child: const Text('Back',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: onNext,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, String subtitle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
