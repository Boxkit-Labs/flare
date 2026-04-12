import 'package:flare_app/core/models/models.dart';

class SavingsService {
  static Map<String, dynamic> calculateTotalSavings(List<FindingModel> findings) {
    double total = 0;
    Map<String, double> categorySavings = {};

    for (var finding in findings) {
       double savings = 0;
       final data = finding.data ?? {};

       switch (finding.type.toLowerCase()) {
         case 'flights':
         case 'flight':
           final prev = data['previous_price'] ?? data['previous_value'] ?? data['old_price'];
           final curr = data['price'] ?? data['current_value'] ?? data['new_price'];
           if (prev != null && curr != null) {
              savings = (prev - curr).toDouble().clamp(0, double.infinity);
           }
           break;
         case 'products':
         case 'product':
           final prev = data['previous_price'] ?? data['previous_value'] ?? data['target_price'];
           final curr = data['price'] ?? data['current_value'] ?? data['found_price'];
           if (prev != null && curr != null) {
              savings = (prev - curr).toDouble().clamp(0, double.infinity);
           }
           break;
         case 'crypto':
         case 'stock':
         case 'stocks':

           final change = data['change_percent'] ?? 0.0;
           if (change > 0) {
              savings = (change / 100.0) * 1000;
           }
           break;
         case 'sports':
           final prev = data['previous_price'] ?? 250.0;
           final curr = data['price'] ?? 150.0;
           savings = (prev - curr).toDouble().clamp(0, double.infinity);
           break;
          default:
           savings = 0;
       }

       if (savings > 0) {
         total += savings;
         categorySavings[finding.type] = (categorySavings[finding.type] ?? 0) + savings;
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
