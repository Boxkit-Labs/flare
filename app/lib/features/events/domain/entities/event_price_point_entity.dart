import 'package:equatable/equatable.dart';

class EventPricePointEntity extends Equatable {
  final DateTime checkedAt;
  final String tierName;
  final double price;
  final bool available;
  final int? quantityRemaining;

  const EventPricePointEntity({
    required this.checkedAt,
    required this.tierName,
    required this.price,
    required this.available,
    this.quantityRemaining,
  });

  @override
  List<Object?> get props => [
        checkedAt,
        tierName,
        price,
        available,
        quantityRemaining,
      ];
}
