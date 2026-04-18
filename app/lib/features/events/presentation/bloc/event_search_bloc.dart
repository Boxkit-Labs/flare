import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/features/events/domain/usecases/search_events_usecase.dart';
import 'event_search_event.dart';
import 'event_search_state.dart';
import 'event_search_filters.dart';
import 'package:flare_app/core/utils/locale_detector.dart';

class EventSearchBloc extends Bloc<EventSearchEvent, EventSearchState> {
  final SearchEventsUseCase searchEventsUseCase;
  Timer? _debounce;
  static const int _pageSize = 20;

  EventSearchBloc({required this.searchEventsUseCase}) : super(const EventSearchInitial()) {
    on<LoadInitialEvents>(_onLoadInitialEvents);
    on<SearchEvents>(_onSearchEvents);
    on<UpdateQuery>(_onUpdateQuery);
    on<UpdateCity>(_onUpdateCity);
    on<UpdateCountry>(_onUpdateCountry);
    on<UpdateCategory>(_onUpdateCategory);
    on<UpdatePlatform>(_onUpdatePlatform);
    on<UpdatePriceRange>(_onUpdatePriceRange);
    on<ToggleFreeOnly>(_onToggleFreeOnly);
    on<UpdateDateRange>(_onUpdateDateRange);
    on<ClearFilters>(_onClearFilters);
    on<ApplyFilters>(_onApplyFilters);
    on<LoadMoreResults>(_onLoadMoreResults);
  }

  Future<void> _onLoadInitialEvents(LoadInitialEvents event, Emitter<EventSearchState> emit) async {
    final localeInfo = LocaleDetector.detect();
    
    // Initialize filters based on detected locale if currently at initial state
    if (state is EventSearchInitial) {
      final initialFilters = state.filters.copyWith(
        city: localeInfo.defaultCity,
        country: localeInfo.countryCode,
        platform: localeInfo.defaultPlatform,
      );
      emit(EventSearchInitial(filters: initialFilters));
    }
    
    add(SearchEvents());
  }

  Future<void> _onSearchEvents(SearchEvents event, Emitter<EventSearchState> emit) async {
    emit(EventSearchLoading(events: state.events, filters: state.filters));

    final result = await searchEventsUseCase(SearchEventsParams(
      query: state.filters.query,
      city: state.filters.city,
      country: state.filters.country,
      category: state.filters.category,
      platform: state.filters.platform,
      date: state.filters.date,
      isFree: state.filters.isFreeOnly ? true : null,
      page: 1,
      limit: _pageSize,
    ));

    result.fold(
      (failure) => emit(EventSearchError(
        message: failure.message,
        events: state.events,
        filters: state.filters,
      )),
      (events) {
        if (events.isEmpty) {
          emit(EventSearchEmpty(filters: state.filters));
        } else {
          emit(EventSearchLoaded(
            events: events,
            filters: state.filters,
            hasReachedMax: events.length < _pageSize,
          ));
        }
      },
    );
  }

  void _onUpdateQuery(UpdateQuery event, Emitter<EventSearchState> emit) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    
    final newFilters = state.filters.copyWith(query: event.query);
    emit(EventSearchLoading(events: state.events, filters: newFilters));

    _debounce = Timer(const Duration(milliseconds: 300), () {
      add(SearchEvents());
    });
  }

  void _onUpdateCity(UpdateCity event, Emitter<EventSearchState> emit) {
    emit(EventSearchLoading(events: state.events, filters: state.filters.copyWith(city: event.city)));
    add(SearchEvents());
  }

  void _onUpdateCountry(UpdateCountry event, Emitter<EventSearchState> emit) {
    emit(EventSearchLoading(events: state.events, filters: state.filters.copyWith(country: event.country)));
    add(SearchEvents());
  }

  void _onUpdateCategory(UpdateCategory event, Emitter<EventSearchState> emit) {
    emit(EventSearchLoading(events: state.events, filters: state.filters.copyWith(category: event.category)));
    add(SearchEvents());
  }

  void _onUpdatePlatform(UpdatePlatform event, Emitter<EventSearchState> emit) {
    emit(EventSearchLoading(events: state.events, filters: state.filters.copyWith(platform: event.platform)));
    add(SearchEvents());
  }

  void _onUpdatePriceRange(UpdatePriceRange event, Emitter<EventSearchState> emit) {
    emit(EventSearchLoading(
      events: state.events, 
      filters: state.filters.copyWith(minPrice: event.min, maxPrice: event.max)
    ));
    add(SearchEvents());
  }

  void _onToggleFreeOnly(ToggleFreeOnly event, Emitter<EventSearchState> emit) {
    emit(EventSearchLoading(
      events: state.events, 
      filters: state.filters.copyWith(isFreeOnly: !state.filters.isFreeOnly)
    ));
    add(SearchEvents());
  }

  void _onUpdateDateRange(UpdateDateRange event, Emitter<EventSearchState> emit) {
    emit(EventSearchLoading(events: state.events, filters: state.filters.copyWith(date: event.date)));
    add(SearchEvents());
  }

  void _onClearFilters(ClearFilters event, Emitter<EventSearchState> emit) {
    emit(const EventSearchInitial());
    add(SearchEvents());
  }

  void _onApplyFilters(ApplyFilters event, Emitter<EventSearchState> emit) {
    emit(EventSearchLoading(events: state.events, filters: event.filters));
    add(SearchEvents());
  }

  Future<void> _onLoadMoreResults(LoadMoreResults event, Emitter<EventSearchState> emit) async {
    if (state is! EventSearchLoaded || (state as EventSearchLoaded).hasReachedMax) return;

    emit(EventSearchLoadingMore(events: state.events, filters: state.filters));

    final nextPage = (state.events.length / _pageSize).ceil() + 1;

    final result = await searchEventsUseCase(SearchEventsParams(
      query: state.filters.query,
      city: state.filters.city,
      country: state.filters.country,
      category: state.filters.category,
      platform: state.filters.platform,
      date: state.filters.date,
      isFree: state.filters.isFreeOnly ? true : null,
      page: nextPage,
      limit: _pageSize,
    ));

    result.fold(
      (failure) => emit(EventSearchError(
        message: failure.message,
        events: state.events,
        filters: state.filters,
      )),
      (newEvents) {
        emit(EventSearchLoaded(
          events: List.from(state.events)..addAll(newEvents),
          filters: state.filters,
          hasReachedMax: newEvents.length < _pageSize,
        ));
      },
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
