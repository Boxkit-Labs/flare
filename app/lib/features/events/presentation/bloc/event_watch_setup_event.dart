import 'package:equatable/equatable.dart';
import 'package:flare_app/features/events/domain/entities/event_entity.dart';

abstract class EventWatchSetupEvent extends Equatable {
  const EventWatchSetupEvent();

  @override
  List<Object?> get props => [];
}

class InitializeWatchSetup extends EventWatchSetupEvent {
  final EventEntity event;
  const InitializeWatchSetup(this.event);

  @override
  List<Object?> get props => [event];
}

class SelectTier extends EventWatchSetupEvent {
  final String tierName;
  final bool selected;
  const SelectTier(this.tierName, this.selected);

  @override
  List<Object?> get props => [tierName, selected];
}

class TogglePriceAlert extends EventWatchSetupEvent {
  final bool enabled;
  const TogglePriceAlert(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ToggleAvailabilityAlert extends EventWatchSetupEvent {
  final bool enabled;
  const ToggleAvailabilityAlert(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class SetCheckFrequency extends EventWatchSetupEvent {
  final Duration frequency;
  const SetCheckFrequency(this.frequency);

  @override
  List<Object?> get props => [frequency];
}

class SubmitWatch extends EventWatchSetupEvent {}
