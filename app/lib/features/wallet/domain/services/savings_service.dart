import 'package:flare_app/core/models/models.dart';

class SavingsService {
  static Map<String, dynamic> calculateTotalSavings(List<FindingModel> findings) {
    double total = 0;
    Map<String, double> categorySavings = {};

    for (var finding in findings) {
      double savings = 0;
      final data = finding.data ?? {};
      final type = (finding.watcherType ?? finding.type).toLowerCase();

      switch (type) {
        case 'flight':
        case 'flights':
          final prev = data['previous_price'] ?? 800.0;
          final curr = data['cheapest_price'] ?? data['price'] ?? 0.0;
          if (curr > 0) {
            savings = (prev.toDouble() - curr.toDouble()).clamp(0.0, 1000.0);
          }
          break;

        case 'crypto':
        case 'stock':
        case 'stocks':
          final assets = data['assets'] as Map<String, dynamic>?;
          if (assets != null && assets.isNotEmpty) {
            final firstAsset = assets.values.first;
            final change = (firstAsset['change_24h'] ?? 0.0).toDouble().abs();
            if (change > 0) {
              savings = (change / 100.0) * 1000;
            }
          } else {
            final change = (data['change_percent'] ?? data['change'] ?? 0.0).toDouble().abs();
            if (change > 0) {
              savings = (change / 100.0) * 1000;
            }
          }
          break;

        case 'product':
        case 'products':
          final prev = data['previous_price'] ?? data['target_price'] ?? 0.0;
          final curr = data['found_price'] ?? data['price'] ?? 0.0;
          if (prev > 0 && curr > 0) {
            savings = (prev.toDouble() - curr.toDouble()).clamp(0.0, double.infinity);
          }
          break;

        default:
          savings = 0;
      }

      if (savings > 0) {
        total += savings;
        final catKey = type.isNotEmpty ? type : 'other';
        categorySavings[catKey] = (categorySavings[catKey] ?? 0) + savings;
      }
    }

    return {
      'total': total,
      'byCategory': categorySavings,
      'findingsCount': findings.length,
    };
  }

  static double calculateROI(double totalSavings, double totalSpent) {
    if (totalSpent <= 0) return 0;
    return totalSavings / totalSpent;
  }
}
