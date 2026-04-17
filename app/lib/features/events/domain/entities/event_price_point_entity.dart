import 'package:equatable/equatable.dart';

class EventPricePointEntity extends Equatable {
  final DateTime checkedAt;
  final String tierName;
  final double minPrice;
  final double maxPrice;
  final bool available;
  final int? quantityRemaining;

  const EventPricePointEntity({
    required this.checkedAt,
    required this.tierName,
    required this.minPrice,
    required this.maxPrice,
    required this.available,
    this.quantityRemaining,
  });

  @override
  List<Object?> get props => [
        checkedAt,
        tierName,
        minPrice,
        maxPrice,
        available,
        quantityRemaining,
      ];
}
