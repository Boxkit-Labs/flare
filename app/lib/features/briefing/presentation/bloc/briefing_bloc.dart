import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/services/api_service.dart';
import 'package:flare_app/core/models/models.dart';
import 'briefing_event.dart';
import 'briefing_state.dart';
import 'package:flare_app/core/utils/error_formatter.dart';

class BriefingBloc extends Bloc<BriefingEvent, BriefingState> {
  final ApiService apiService;

  BriefingBloc(this.apiService) : super(BriefingInitial()) {
    on<LoadTodayBriefing>((event, emit) async {
      if (!event.isRefresh) emit(BriefingLoading());
      try {
        final today = await apiService.getTodayBriefing(event.userId);
        emit(BriefingLoaded(todayBriefing: today));
      } catch (e) {
        if (!event.isRefresh) emit(BriefingError(ErrorFormatter.format(e)));
      }
    });

    on<LoadBriefingHistory>((event, emit) async {
      emit(BriefingLoading());
      try {
        final history = await apiService.getBriefings(event.userId, limit: event.limit);
        emit(BriefingLoaded(history: history));
      } catch (e) {
        emit(BriefingError(ErrorFormatter.format(e)));
      }
    });

    on<GenerateManualBriefing>((event, emit) async {
      emit(BriefingGenerating());
      try {
        final briefing = await apiService.generateBriefing(event.userId);
        emit(BriefingGenerated(briefing));

      } catch (e) {
        emit(BriefingError(ErrorFormatter.format(e)));
      }
    });

    on<MarkBriefingRead>((event, emit) async {
      try {
        await apiService.markBriefingRead(event.briefingId);
        if (state is BriefingLoaded) {
          final cur = (state as BriefingLoaded);
          if (cur.todayBriefing?.briefingId == event.briefingId) {

             emit(BriefingLoaded(
               todayBriefing: null,
               history: cur.history,
             ));
          }
        }
      } catch (e) {

      }
    });

    on<LoadBriefingByDate>((event, emit) async {
      final dateKey = event.date.toIso8601String().split('T')[0];

      if (state is BriefingLoaded) {
        final current = state as BriefingLoaded;
        if (current.briefingsByDate.containsKey(dateKey)) {
          return;
        }
      }

      emit(state is BriefingLoaded ? state : BriefingLoading());

      try {
        final briefing = await apiService.getBriefingByDate(event.userId, dateKey);

        if (state is BriefingLoaded) {
          final current = state as BriefingLoaded;
          final updatedMap = Map<String, BriefingModel?>.from(current.briefingsByDate);
          updatedMap[dateKey] = briefing;

          emit(BriefingLoaded(
            todayBriefing: current.todayBriefing,
            history: current.history,
            briefingsByDate: updatedMap,
          ));
        } else {
          emit(BriefingLoaded(
            briefingsByDate: {dateKey: briefing},
          ));
        }
      } catch (e) {
        emit(BriefingError(ErrorFormatter.format(e)));
      }
    });
  }
}
