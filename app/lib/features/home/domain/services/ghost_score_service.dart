import 'package:flare_app/core/models/models.dart';

class GhostScoreService {
  static Map<String, dynamic> calculate(
    List<FindingModel> findings,
    List<WatcherModel> watchers,
    double totalSpent,
    int streak,
  ) {
    // 1. Efficiency (0-30): Findings per dollar
    // Benchmark: $0.50 per finding is good efficiency.
    double findingsPerDollar = totalSpent > 0 ? findings.length / totalSpent : 0.0;
    double efficiencyS = (findingsPerDollar / 2.0).clamp(0.0, 1.0) * 30;

    // 2. Savings (0-25): Estimate total savings from findings
    double totalSavings = 0;
    for (var f in findings) {
      if (f.data != null) {
        final prev = f.data!['previous_price'] ?? f.data!['previous_value'];
        final curr = f.data!['price'] ?? f.data!['current_value'];
        if (prev != null && curr != null) {
          totalSavings += (prev - curr).abs();
        }
      }
    }
    double savingsRatio = totalSpent > 0 ? totalSavings / totalSpent : 0.0;
    double savingsS = (savingsRatio / 100.0).clamp(0.0, 1.0) * 25; // Good ROI = 100x

    // 3. Coverage (0-20): Unique active categories
    Set<String> categories = watchers.where((w) => w.status == 'active').map((w) => w.type).toSet();
    double coverageS = (categories.length / 8.0).clamp(0.0, 1.0) * 20;

    // 4. Reliability (0-15): Avg confidence score
    double avgConfidence = findings.isEmpty 
        ? 0 
        : findings.fold(0, (sum, f) => sum + f.confidenceScore) / findings.length;
    double reliabilityS = (avgConfidence / 100.0).clamp(0.0, 1.0) * 15;

    // 5. Consistency (0-10): Streak
    double consistencyS = (streak / 7.0).clamp(0.0, 1.0) * 10;

    double total = efficiencyS + savingsS + coverageS + reliabilityS + consistencyS;
    int roundedTotal = total.round();

    return {
      'score': roundedTotal,
      'tier': _getTier(roundedTotal),
      'breakdown': {
        'Efficiency': efficiencyS / 30,
        'Savings': savingsS / 25,
        'Coverage': coverageS / 20,
        'Reliability': reliabilityS / 15,
        'Consistency': consistencyS / 10,
      },
      'stats': {
        'totalSavings': totalSavings,
        'activeCategories': categories.length,
        'avgConfidence': avgConfidence,
      }
    };
  }

  static Map<String, dynamic> _getTier(int score) {
    if (score >= 90) return {'name': 'Ghost Master 👻', 'color': 'purple', 'icon': '🏆'};
    if (score >= 75) return {'name': 'Agent Pro', 'color': 'gold', 'icon': '🌟'};
    if (score >= 60) return {'name': 'Smart Watcher', 'color': 'blue', 'icon': '🧠'};
    if (score >= 40) return {'name': 'Getting Started', 'color': 'green', 'icon': '🌱'};
    return {'name': 'Rookie', 'color': 'grey', 'icon': '👤'};
  }
}
