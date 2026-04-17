import 'package:equatable/equatable.dart';
import 'package:flare_app/features/events/domain/entities/event_price_point_entity.dart';

abstract class EventPriceHistoryState extends Equatable {
  final List<EventPricePointEntity> allPoints;
  final Set<String> visibleTiers;
  final DateTime? startDate;
  final DateTime? endDate;

  const EventPriceHistoryState({
    this.allPoints = const [],
    this.visibleTiers = const {},
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [allPoints, visibleTiers, startDate, endDate];

  /// Returns the data grouped by tier name, filtered by date range and visibility.
  Map<String, List<EventPricePointEntity>> get filteredData {
    final Map<String, List<EventPricePointEntity>> grouped = {};
    
    for (final point in allPoints) {
      if (!visibleTiers.contains(point.tierName)) continue;
      
      if (startDate != null && point.checkedAt.isBefore(startDate!)) continue;
      if (endDate != null && point.checkedAt.isAfter(endDate!)) continue;
      
      if (!grouped.containsKey(point.tierName)) {
        grouped[point.tierName] = [];
      }
      grouped[point.tierName]!.add(point);
    }
    
    return grouped;
  }
}

class EventPriceHistoryInitial extends EventPriceHistoryState {}

class EventPriceHistoryLoading extends EventPriceHistoryState {}

class EventPriceHistoryLoaded extends EventPriceHistoryState {
  const EventPriceHistoryLoaded({
    required super.allPoints,
    required super.visibleTiers,
    super.startDate,
    super.endDate,
  });
}

class EventPriceHistoryEmpty extends EventPriceHistoryState {}

class EventPriceHistoryError extends EventPriceHistoryState {
  final String message;

  const EventPriceHistoryError(this.message);

  @override
  List<Object?> get props => [super.props, message];
}
