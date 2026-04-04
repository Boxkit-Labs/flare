import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/models/models.dart';
import 'package:intl/intl.dart';

class AnalyticsChart extends StatelessWidget {
  final WatcherModel watcher;

  const AnalyticsChart({super.key, required this.watcher});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         const Text('Metric Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
         const SizedBox(height: 16),
         AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
               _buildLineData(),
            ),
         ),
         const SizedBox(height: 32),
         const Text('Daily Consumption', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
         const SizedBox(height: 16),
         AspectRatio(
            aspectRatio: 1.7,
            child: BarChart(
               _buildBarData(),
            ),
         ),
      ],
    );
  }

  LineChartData _buildLineData() {
    final List<CheckModel> checks = watcher.recentChecks ?? [];
    if (checks.isEmpty) return LineChartData();

    final List<FlSpot> spots = [];
    for (int i = 0; i < checks.length; i++) {
       final val = (checks[i].responseData?['price'] ?? checks[i].responseData?['count'] ?? 0).toDouble();
       spots.add(FlSpot(i.toDouble(), val));
    }

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppTheme.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
               final check = checks[index.toInt()];
               return FlDotCirclePainter(
                 radius: check.findingDetected ? 6 : 0,
                 color: Colors.orange,
                 strokeWidth: 2,
                 strokeColor: AppTheme.surface,
               );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [AppTheme.primary.withValues(alpha: 0.3), AppTheme.primary.withValues(alpha: 0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  BarChartData _buildBarData() {
    // Generate dummy data if real history is sparse
    final List<BarChartGroupData> groups = [];
    for (int i = 0; i < 7; i++) {
        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: (i + 1) * 0.05, // Dummy consumption
                color: AppTheme.secondary,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
    }

    return BarChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) {
               final date = DateTime.now().subtract(Duration(days: 6 - val.toInt()));
               return Padding(
                 padding: const EdgeInsets.only(top: 8),
                 child: Text(DateFormat('E').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
               );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: groups,
    );
  }
}
