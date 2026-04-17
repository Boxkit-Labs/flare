import 'package:equatable/equatable.dart';

class TicketTierEntity extends Equatable {
  final String name;
  final double minPrice;
  final double maxPrice;
  final String currency;
  final bool available;
  final int? quantityRemaining;
  final int? quantityTotal;
  final DateTime? onSaleDate;
  final DateTime? offSaleDate;

  const TicketTierEntity({
    required this.name,
    required this.minPrice,
    required this.maxPrice,
    required this.currency,
    required this.available,
    this.quantityRemaining,
    this.quantityTotal,
    this.onSaleDate,
    this.offSaleDate,
  });

  String get displayPrice {
    if (minPrice == maxPrice) {
      return '$currency ${minPrice.toStringAsFixed(2)}';
    }
    return '$currency ${minPrice.toStringAsFixed(2)} - ${maxPrice.toStringAsFixed(2)}';
  }

  String get availabilityText {
    if (!available) return 'Sold Out';
    if (quantityRemaining != null) {
      if (quantityTotal != null) {
        return '$quantityRemaining / $quantityTotal left';
      }
      return '$quantityRemaining left';
    }
    return 'Available';
  }

  String get availabilityColor {
    if (!available) return '#FF5252'; // Red
    if (quantityRemaining != null && quantityRemaining! < 10) {
      return '#FFAB40'; // Orange
    }
    return '#4CAF50'; // Green
  }

  @override
  List<Object?> get props => [
        name,
        minPrice,
        maxPrice,
        currency,
        available,
        quantityRemaining,
        quantityTotal,
        onSaleDate,
        offSaleDate,
      ];
}
