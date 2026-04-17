import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/features/events/domain/usecases/get_event_price_history_usecase.dart';
import 'event_price_history_event.dart';
import 'event_price_history_state.dart';

class EventPriceHistoryBloc extends Bloc<EventPriceHistoryEvent, EventPriceHistoryState> {
  final GetEventPriceHistoryUseCase getPriceHistoryUseCase;

  EventPriceHistoryBloc({required this.getPriceHistoryUseCase}) : super(EventPriceHistoryInitial()) {
    on<LoadPriceHistory>(_onLoadPriceHistory);
    on<ChangeDateRange>(_onChangeDateRange);
    on<ToggleTier>(_onToggleTier);
  }

  Future<void> _onLoadPriceHistory(LoadPriceHistory event, Emitter<EventPriceHistoryState> emit) async {
    emit(EventPriceHistoryLoading());

    final result = await getPriceHistoryUseCase(GetEventPriceHistoryParams(
      platform: event.platform,
      externalId: event.externalId,
    ));

    result.fold(
      (failure) => emit(EventPriceHistoryError(failure.message)),
      (points) {
        if (points.isEmpty) {
          emit(EventPriceHistoryEmpty());
        } else {
          // By default, visible tiers are all tiers found in history
          final allTiers = points.map((p) => p.tierName).toSet();
          
          emit(EventPriceHistoryLoaded(
            allPoints: points,
            visibleTiers: allTiers,
          ));
        }
      },
    );
  }

  void _onChangeDateRange(ChangeDateRange event, Emitter<EventPriceHistoryState> emit) {
    if (state is! EventPriceHistoryLoaded) return;
    
    final current = state as EventPriceHistoryLoaded;
    emit(EventPriceHistoryLoaded(
      allPoints: current.allPoints,
      visibleTiers: current.visibleTiers,
      startDate: event.start,
      endDate: event.end,
    ));
  }

  void _onToggleTier(ToggleTier event, Emitter<EventPriceHistoryState> emit) {
    if (state is! EventPriceHistoryLoaded) return;

    final current = state as EventPriceHistoryLoaded;
    final newVisibleTiers = Set<String>.from(current.visibleTiers);
    
    if (newVisibleTiers.contains(event.tierName)) {
      newVisibleTiers.remove(event.tierName);
    } else {
      newVisibleTiers.add(event.tierName);
    }

    emit(EventPriceHistoryLoaded(
      allPoints: current.allPoints,
      visibleTiers: newVisibleTiers,
      startDate: current.startDate,
      endDate: current.endDate,
    ));
  }
}
