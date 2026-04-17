import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/core/utils/currency_formatter.dart';
import 'package:flare_app/features/events/domain/entities/event_watcher_params_entity.dart';
import 'package:flare_app/features/events/domain/usecases/create_event_watcher_usecase.dart';
import 'event_watch_setup_event.dart';
import 'event_watch_setup_state.dart';

class EventWatchSetupBloc extends Bloc<EventWatchSetupEvent, EventWatchSetupState> {
  final CreateEventWatcherUseCase createEventWatcherUseCase;

  EventWatchSetupBloc({required this.createEventWatcherUseCase})
      : super(EventWatchSetupState(userCurrency: CurrencyFormatter.detectUserCurrency())) {
    on<InitializeWatchSetup>(_onInitializeWatchSetup);
    on<SelectTier>(_onSelectTier);
    on<TogglePriceAlert>(_onTogglePriceAlert);
    on<ToggleAvailabilityAlert>(_onToggleAvailabilityAlert);
    on<SetCheckFrequency>(_onSetCheckFrequency);
    on<UpdatePriceBelow>(_onUpdatePriceBelow);
    on<UpdatePriceDropPercentage>(_onUpdatePriceDropPercentage);
    on<ToggleAlmostSoldOutAlert>(_onToggleAlmostSoldOutAlert);
    on<SubmitWatch>(_onSubmitWatch);
  }

  void _onInitializeWatchSetup(InitializeWatchSetup event, Emitter<EventWatchSetupState> emit) {
    // Detect free event to disable price conditions
    final isFree = event.event.isFree;
    
    // Smart defaults: select all available tiers
    final initialTiers = event.event.tiers
        .where((t) => t.available)
        .map((t) => t.name)
        .toSet();

    emit(state.copyWith(
      event: event.event,
      selectedTiers: initialTiers,
      priceAlertEnabled: !isFree,
      availabilityAlertEnabled: true,
      status: EventWatchSubmissionStatus.initial,
    ));
  }

  void _onSelectTier(SelectTier event, Emitter<EventWatchSetupState> emit) {
    final newTiers = Set<String>.from(state.selectedTiers);
    if (event.selected) {
      newTiers.add(event.tierName);
    } else {
      newTiers.remove(event.tierName);
    }
    emit(state.copyWith(selectedTiers: newTiers));
  }

  void _onTogglePriceAlert(TogglePriceAlert event, Emitter<EventWatchSetupState> emit) {
    if (state.isFreeEvent) return; // Cannot enable for free events
    emit(state.copyWith(priceAlertEnabled: event.enabled));
  }

  void _onToggleAvailabilityAlert(ToggleAvailabilityAlert event, Emitter<EventWatchSetupState> emit) {
    emit(state.copyWith(availabilityAlertEnabled: event.enabled));
  }

  void _onSetCheckFrequency(SetCheckFrequency event, Emitter<EventWatchSetupState> emit) {
    emit(state.copyWith(frequency: event.frequency));
  }

  void _onUpdatePriceBelow(UpdatePriceBelow event, Emitter<EventWatchSetupState> emit) {
    emit(state.copyWith(priceBelow: event.price));
  }

  void _onUpdatePriceDropPercentage(UpdatePriceDropPercentage event, Emitter<EventWatchSetupState> emit) {
    emit(state.copyWith(priceDropPercentage: event.percentage));
  }

  void _onToggleAlmostSoldOutAlert(ToggleAlmostSoldOutAlert event, Emitter<EventWatchSetupState> emit) {
    emit(state.copyWith(almostSoldOutAlertEnabled: event.enabled));
  }

  Future<void> _onSubmitWatch(SubmitWatch event, Emitter<EventWatchSetupState> emit) async {
    if (!state.isValid) return;

    emit(state.copyWith(status: EventWatchSubmissionStatus.submitting));

    final params = EventWatcherParamsEntity(
      mode: 'specific_event',
      platform: state.event!.platform,
      externalId: state.event!.externalId,
      eventName: state.event!.name,
      watchTiers: state.selectedTiers.toList(),
      // The use case handles internal registration of alerts based on params
      // However our current ParamsEntity is generic, we'll assume the backend 
      // configuration is handled via these fields or a separate alert config.
    );

    final result = await createEventWatcherUseCase(params);

    result.fold(
      (failure) => emit(state.copyWith(
        status: EventWatchSubmissionStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(status: EventWatchSubmissionStatus.success)),
    );
  }
}
