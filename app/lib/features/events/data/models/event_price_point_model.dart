import 'package:flare_app/features/events/domain/entities/event_price_point_entity.dart';

class EventPricePointModel extends EventPricePointEntity {
  const EventPricePointModel({
    required super.checkedAt,
    required super.tierName,
    required super.minPrice,
    required super.maxPrice,
    required super.available,
    super.quantityRemaining,
  });

  factory EventPricePointModel.fromJson(Map<String, dynamic> json) {
    return EventPricePointModel(
      checkedAt: DateTime.parse(json['checkedAt'] as String),
      tierName: json['tierName'] as String,
      minPrice: (json['minPrice'] as num).toDouble(),
      maxPrice: (json['maxPrice'] as num).toDouble(),
      available: json['available'] as bool,
      quantityRemaining: json['quantityRemaining'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkedAt': checkedAt.toIso8601String(),
      'tierName': tierName,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'available': available,
      'quantityRemaining': quantityRemaining,
    };
  }
}
