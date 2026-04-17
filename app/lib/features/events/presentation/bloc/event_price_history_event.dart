import 'package:equatable/equatable.dart';

abstract class EventPriceHistoryEvent extends Equatable {
  const EventPriceHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadPriceHistory extends EventPriceHistoryEvent {
  final String platform;
  final String externalId;

  const LoadPriceHistory({
    required this.platform,
    required this.externalId,
  });

  @override
  List<Object?> get props => [platform, externalId];
}

class ChangeDateRange extends EventPriceHistoryEvent {
  final DateTime start;
  final DateTime end;

  const ChangeDateRange(this.start, this.end);

  @override
  List<Object?> get props => [start, end];
}

class ToggleTier extends EventPriceHistoryEvent {
  final String tierName;

  const ToggleTier(this.tierName);

  @override
  List<Object?> get props => [tierName];
}
