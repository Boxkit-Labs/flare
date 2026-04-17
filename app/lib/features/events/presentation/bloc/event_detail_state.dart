import 'package:equatable/equatable.dart';
import 'package:flare_app/features/events/domain/entities/event_entity.dart';

abstract class EventDetailState extends Equatable {
  final EventEntity? event;

  const EventDetailState({this.event});

  @override
  List<Object?> get props => [event];
}

class EventDetailInitial extends EventDetailState {}

class EventDetailLoading extends EventDetailState {
  const EventDetailLoading({super.event});
}

class EventDetailLoaded extends EventDetailState {
  const EventDetailLoaded(EventEntity event) : super(event: event);
}

class EventDetailError extends EventDetailState {
  final String message;

  const EventDetailError({
    required this.message,
    super.event,
  });

  @override
  List<Object?> get props => [super.props, message];
}
