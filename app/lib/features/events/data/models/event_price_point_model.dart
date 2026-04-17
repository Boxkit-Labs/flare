import 'package:flare_app/features/events/domain/entities/event_price_point_entity.dart';

class EventPricePointModel extends EventPricePointEntity {
  const EventPricePointModel({
    required super.checkedAt,
    required super.tierName,
    required super.price,
    required super.available,
    super.quantityRemaining,
  });

  factory EventPricePointModel.fromJson(Map<String, dynamic> json) {
    return EventPricePointModel(
      checkedAt: DateTime.parse(json['checkedAt'] as String),
      tierName: json['tierName'] as String,
      price: (json['price'] as num).toDouble(),
      available: json['available'] as bool? ?? true,
      quantityRemaining: json['quantityRemaining'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkedAt': checkedAt.toIso8601String(),
      'tierName': tierName,
      'price': price,
      'available': available,
      if (quantityRemaining != null) 'quantityRemaining': quantityRemaining,
    };
  }
}
