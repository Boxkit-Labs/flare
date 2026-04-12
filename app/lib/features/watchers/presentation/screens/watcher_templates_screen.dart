import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/core/theme/app_theme.dart';

class WatcherTemplatesScreen extends StatelessWidget {
  const WatcherTemplatesScreen({super.key});

  final List<Map<String, dynamic>> templates = const [
    {
      'title': 'Cheap Flights to Tokyo',
      'emoji': '✈️',
      'type': 'flight',
      'desc': 'Alert if flights to NRT/HND drop below \$800',
      'params': {'destination': 'Tokyo (NRT)', 'price_below': 800},
    },
    {
      'title': 'Bitcoin Whale Watch',
      'emoji': '💰',
      'type': 'crypto',
      'desc': 'Alert on 5% price moves in BTC',
      'params': {'symbols': ['BTC'], 'change_percent': 5.0},
    },
    {
      'title': 'Nvidia Earnings Play',
      'emoji': '📊',
      'type': 'stock',
      'desc': 'Watch NVDA for volatility & news',
      'params': {'symbols': ['NVDA'], 'mode': 'events'},
    },
    {
       'title': 'Austin Housing Deals',
       'emoji': '🏠',
       'type': 'realestate',
       'desc': 'New 3+ bed listings in Austin under \$600k',
       'params': {'city': 'Austin, TX', 'bedrooms_min': 3, 'price_max': 600000},
    },
    {
       'title': 'Warriors Ticket Drop',
       'emoji': '🏀',
       'type': 'sports',
       'desc': 'Notify if Warriors tickets drop below \$150',
       'params': {'team': 'Warriors', 'price_max': 150},
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Agent Templates', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'One-Tap Deployment',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pre-configured high-intelligence agents ready to hunt.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: templates.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final template = templates[index];
                return _buildTemplateCard(context, template);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, Map<String, dynamic> template) {
    return InkWell(
      onTap: () {

        context.push('/watchers/create', extra: template);
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(template['emoji'], style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template['title'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(template['desc'], style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
