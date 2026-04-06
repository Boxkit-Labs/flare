import 'package:flutter/material.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class SpendingHeatmap extends StatelessWidget {
  final List<dynamic> dailySpending; // List of {date: string, amount: double, findings: int}
  final Function(Map<String, dynamic>) onDayTap;

  const SpendingHeatmap({
    super.key,
    required this.dailySpending,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    // Generate last 84 days (12 weeks)
    final now = DateTime.now();
    final days = List.generate(84, (index) {
      final date = now.subtract(Duration(days: 83 - index));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      final data = dailySpending.firstWhere(
        (d) => d['date'] == dateStr,
        orElse: () => {'date': dateStr, 'amount': 0.0, 'findings': 0},
      );
      
      return data;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agent Activity Heatmap',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          ),
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 12, // 12 weeks
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: 84,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final amount = day['amount'] as double;
                  final hasFindings = (day['findings'] ?? 0) > 0;

                  return GestureDetector(
                    onTap: () => onDayTap(day),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getHeatColor(amount),
                        borderRadius: BorderRadius.circular(3),
                        border: hasFindings ? Border.all(color: Colors.amber, width: 1.5) : null,
                      ),
                      child: hasFindings 
                          ? const Center(child: Text('⭐', style: TextStyle(fontSize: 6)))
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Less ', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                  _buildLegendBox(Colors.grey.withValues(alpha: 0.1)),
                  _buildLegendBox(Colors.green.withValues(alpha: 0.2)),
                  _buildLegendBox(Colors.green.withValues(alpha: 0.4)),
                  _buildLegendBox(Colors.green.withValues(alpha: 0.7)),
                  _buildLegendBox(Colors.green),
                  const Text(' More', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }

  Color _getHeatColor(double amount) {
    if (amount <= 0) return Colors.grey.withValues(alpha: 0.1);
    if (amount < 0.01) return Colors.green.withValues(alpha: 0.2);
    if (amount < 0.05) return Colors.green.withValues(alpha: 0.4);
    if (amount < 0.10) return Colors.green.withValues(alpha: 0.7);
    return Colors.green;
  }
}
