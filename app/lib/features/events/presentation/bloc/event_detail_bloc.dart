import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/features/events/domain/usecases/get_event_detail_usecase.dart';
import 'event_detail_event.dart';
import 'event_detail_state.dart';

class EventDetailBloc extends Bloc<EventDetailEvent, EventDetailState> {
  final GetEventDetailUseCase getEventDetailUseCase;
  String? _lastPlatform;
  String? _lastExternalId;

  EventDetailBloc({required this.getEventDetailUseCase}) : super(EventDetailInitial()) {
    on<LoadEventDetail>(_onLoadEventDetail);
    on<RefreshEventDetail>(_onRefreshEventDetail);
  }

  Future<void> _onLoadEventDetail(LoadEventDetail event, Emitter<EventDetailState> emit) async {
    _lastPlatform = event.platform;
    _lastExternalId = event.externalId;

    // Emit loading with initial entity immediately for instant display
    emit(EventDetailLoading(event: event.initialEntity));

    await _fetchDetail(emit);
  }

  Future<void> _onRefreshEventDetail(RefreshEventDetail event, Emitter<EventDetailState> emit) async {
    if (_lastPlatform == null || _lastExternalId == null) return;

    emit(EventDetailLoading(event: state.event));
    await _fetchDetail(emit);
  }

  Future<void> _fetchDetail(Emitter<EventDetailState> emit) async {
    if (_lastPlatform == null || _lastExternalId == null) return;

    final result = await getEventDetailUseCase(GetEventDetailParams(
      platform: _lastPlatform!,
      externalId: _lastExternalId!,
    ));

    result.fold(
      (failure) => emit(EventDetailError(
        message: failure.message,
        event: state.event, // Preserve stale data on error
      )),
      (event) => emit(EventDetailLoaded(event)),
    );
  }
}
