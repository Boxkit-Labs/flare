import 'package:flare_app/features/events/domain/entities/ticket_tier_entity.dart';

class TicketTierModel extends TicketTierEntity {
  const TicketTierModel({
    required super.name,
    required super.minPrice,
    required super.maxPrice,
    required super.currency,
    required super.available,
    super.quantityRemaining,
    super.quantityTotal,
    super.onSaleDate,
    super.offSaleDate,
  });

  factory TicketTierModel.fromJson(Map<String, dynamic> json) {
    return TicketTierModel(
      name: json['name'] as String,
      minPrice: (json['minPrice'] as num).toDouble(),
      maxPrice: (json['maxPrice'] as num).toDouble(),
      currency: json['currency'] as String,
      available: json['available'] as bool,
      quantityRemaining: json['quantityRemaining'] as int?,
      quantityTotal: json['quantityTotal'] as int?,
      onSaleDate: json['onSaleDate'] != null ? DateTime.parse(json['onSaleDate'] as String) : null,
      offSaleDate: json['offSaleDate'] != null ? DateTime.parse(json['offSaleDate'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'currency': currency,
      'available': available,
      'quantityRemaining': quantityRemaining,
      'quantityTotal': quantityTotal,
      'onSaleDate': onSaleDate?.toIso8601String(),
      'offSaleDate': offSaleDate?.toIso8601String(),
    };
  }
}
