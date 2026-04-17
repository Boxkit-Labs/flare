import 'package:equatable/equatable.dart';
import 'package:flare_app/features/events/domain/entities/event_entity.dart';

abstract class EventDetailEvent extends Equatable {
  const EventDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadEventDetail extends EventDetailEvent {
  final String platform;
  final String externalId;
  final EventEntity? initialEntity;

  const LoadEventDetail({
    required this.platform,
    required this.externalId,
    this.initialEntity,
  });

  @override
  List<Object?> get props => [platform, externalId, initialEntity];
}

class RefreshEventDetail extends EventDetailEvent {}
