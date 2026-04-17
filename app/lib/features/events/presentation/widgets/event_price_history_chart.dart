import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flare_app/core/utils/currency_formatter.dart';
import 'package:flare_app/features/events/domain/entities/event_price_point_entity.dart';

class EventPriceHistoryChart extends StatelessWidget {
  final Map<String, List<EventPricePointEntity>> groupedData;
  final String currency;
  final bool animate;

  const EventPriceHistoryChart({
    super.key,
    required this.groupedData,
    this.currency = 'USD',
    this.animate = true,
  });

  static const List<Color> _tierColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFF43F5E), // Rose
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
  ];

  @override
  Widget build(BuildContext context) {
    if (groupedData.isEmpty) {
      return const Center(
        child: Text(
          'No historical data available for these tiers',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
      );
    }

    // Flatten data to find ranges
    final allPoints = groupedData.values.expand((e) => e).toList();
    if (allPoints.isEmpty) return const SizedBox.shrink();

    final minPrice = allPoints.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    final maxPrice = allPoints.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    final minTime = allPoints.map((p) => p.checkedAt.millisecondsSinceEpoch).reduce((a, b) => a < b ? a : b).toDouble();
    final maxTime = allPoints.map((p) => p.checkedAt.millisecondsSinceEpoch).reduce((a, b) => a > b ? a : b).toDouble();

    final timeRange = maxTime - minTime;
    final pricePadding = (maxPrice - minPrice) * 0.15;

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        duration: animate ? const Duration(milliseconds: 1000) : Duration.zero,
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withOpacity(0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: timeRange > 0 ? timeRange / 4 : 1,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MMM d').format(date),
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (maxPrice - minPrice) > 0 ? (maxPrice - minPrice) / 3 : 1,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    CurrencyFormatter.formatCurrency(value, currency),
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: minTime,
          maxX: maxTime,
          minY: minPrice - pricePadding,
          maxY: maxPrice + pricePadding,
          lineBarsData: _buildLineBars(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1E293B),
              tooltipBorder: BorderSide(color: Colors.white.withOpacity(0.1)),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                  final tierName = groupedData.keys.elementAt(spot.barIndex);
                  return LineTooltipItem(
                    '${DateFormat('MMM d, HH:mm').format(date)}\n',
                    const TextStyle(color: Colors.white70, fontSize: 10),
                    children: [
                      TextSpan(
                        text: '$tierName: ',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      TextSpan(
                        text: CurrencyFormatter.formatCurrency(spot.y, currency),
                        style: TextStyle(color: _tierColors[spot.barIndex % _tierColors.length], fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLineBars() {
    final List<LineChartBarData> bars = [];
    int index = 0;

    groupedData.forEach((tierName, points) {
      if (points.isEmpty) return;

      // Ensure points are sorted by date
      points.sort((a, b) => a.checkedAt.compareTo(b.checkedAt));

      final color = _tierColors[index % _tierColors.length];

      bars.add(
        LineChartBarData(
          spots: points.map((p) => FlSpot(p.checkedAt.millisecondsSinceEpoch.toDouble(), p.price)).toList(),
          isCurved: true,
          color: color,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: points.length == 1,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: color,
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
      index++;
    });

    return bars;
  }
}
