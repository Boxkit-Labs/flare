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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(_getChartTitle(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
               _buildTypeBadge(),
             ],
           ),
           const SizedBox(height: 16),
           AspectRatio(
              aspectRatio: 1.7,
              child: _buildMainChart(),
           ),
           const SizedBox(height: 32),
           const Text('Ghost Consumption (USDC)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
           const SizedBox(height: 16),
           AspectRatio(
              aspectRatio: 2.2,
              child: BarChart(
                 _buildConsumptionData(),
              ),
           ),
           const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getChartTitle() {
    switch (watcher.type.toLowerCase()) {
      case 'flight': return 'Price Floor History';
      case 'crypto': return 'Price Volatility';
      case 'news': return 'Article Density';
      case 'product': return 'Market Variations';
      case 'stock': return 'Candlestick Trend';
      default: return 'Agent Activity';
    }
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        watcher.type.toUpperCase(),
        style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildMainChart() {
    final type = watcher.type.toLowerCase();
    if (type == 'news' || type == 'job') {
      return BarChart(_buildVolumeData());
    }
    return LineChart(_buildMetricData());
  }

  LineChartData _buildMetricData() {
    final List<CheckModel> checks = watcher.recentChecks ?? [];
    if (checks.isEmpty) return LineChartData();

    final List<FlSpot> spots = [];
    for (int i = 0; i < checks.length; i++) {
       final data = checks[i].responseData;
       double val = 0;
       if (data != null) {
          val = (data['price'] ?? data['priceUsd'] ?? data['price_usd'] ?? 0).toDouble();
       }
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
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
               final check = checks[index.toInt()];
               return FlDotCirclePainter(
                 radius: check.findingDetected ? 6 : 0,
                 color: Colors.orange,
                 strokeWidth: 3,
                 strokeColor: Colors.white,
               );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [AppTheme.primary.withValues(alpha: 0.2), AppTheme.primary.withValues(alpha: 0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  BarChartData _buildVolumeData() {
    final List<CheckModel> checks = watcher.recentChecks ?? [];
    final List<BarChartGroupData> groups = [];

    for (int i = 0; i < checks.length; i++) {
        final data = checks[i].responseData;
        double val = 0;
        if (data != null) {
           val = (data['articles']?.length ?? data['jobs']?.length ?? data['count'] ?? 5).toDouble();
        }
        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: val,
                color: checks[i].findingDetected ? Colors.amber : AppTheme.secondary,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
    }

    return BarChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: groups,
    );
  }

  BarChartData _buildConsumptionData() {
    final List<BarChartGroupData> groups = [];
    for (int i = 0; i < 7; i++) {
        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: 0.008 * (i + 1),
                color: Colors.black12,
                width: 20,
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
                 child: Text(DateFormat('E').format(date).toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
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
