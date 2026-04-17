import 'package:equatable/equatable.dart';
import 'package:flare_app/features/events/domain/entities/event_entity.dart';
import 'event_search_filters.dart';

abstract class EventSearchState extends Equatable {
  final List<EventEntity> events;
  final EventSearchFilters filters;

  const EventSearchState({
    this.events = const [],
    this.filters = const EventSearchFilters(),
  });

  @override
  List<Object?> get props => [events, filters];
}

class EventSearchInitial extends EventSearchState {
  const EventSearchInitial() : super();
}

class EventSearchLoading extends EventSearchState {
  const EventSearchLoading({
    super.events,
    super.filters,
  });
}

class EventSearchLoaded extends EventSearchState {
  final bool hasReachedMax;

  const EventSearchLoaded({
    required super.events,
    required super.filters,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [super.props, hasReachedMax];
}

class EventSearchLoadingMore extends EventSearchState {
  const EventSearchLoadingMore({
    required super.events,
    required super.filters,
  });
}

class EventSearchError extends EventSearchState {
  final String message;

  const EventSearchError({
    required this.message,
    super.events,
    super.filters,
  });

  @override
  List<Object?> get props => [super.props, message];
}

class EventSearchEmpty extends EventSearchState {
  const EventSearchEmpty({
    super.filters,
  }) : super(events: const []);
}
