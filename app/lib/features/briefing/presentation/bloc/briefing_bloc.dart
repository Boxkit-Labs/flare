import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/services/api_service.dart';
import 'briefing_event.dart';
import 'briefing_state.dart';

class BriefingBloc extends Bloc<BriefingEvent, BriefingState> {
  final ApiService apiService;

  BriefingBloc(this.apiService) : super(BriefingInitial()) {
    on<LoadTodayBriefing>((event, emit) async {
      emit(BriefingLoading());
      try {
        final today = await apiService.getTodayBriefing(event.userId);
        emit(BriefingLoaded(todayBriefing: today));
      } catch (e) {
        emit(BriefingError(e.toString()));
      }
    });

    on<LoadBriefingHistory>((event, emit) async {
      emit(BriefingLoading());
      try {
        final history = await apiService.getBriefings(event.userId, limit: event.limit);
        emit(BriefingLoaded(history: history));
      } catch (e) {
        emit(BriefingError(e.toString()));
      }
    });

    on<GenerateManualBriefing>((event, emit) async {
      emit(BriefingGenerating());
      try {
        final briefing = await apiService.generateBriefing(event.userId);
        emit(BriefingGenerated(briefing));
        // No auto-dispatch of LoadTodayBriefing here to avoid state flicker
        // but the generated briefing is sent to the success state
      } catch (e) {
        emit(BriefingError(e.toString()));
      }
    });

    on<MarkBriefingRead>((event, emit) async {
      try {
        await apiService.markBriefingRead(event.briefingId);
        if (state is BriefingLoaded) {
          final cur = (state as BriefingLoaded);
          if (cur.todayBriefing?.briefingId == event.briefingId) {
             // In-place update (simple)
             emit(BriefingLoaded(
               todayBriefing: null, // Just hide it from dashboard
               history: cur.history,
             ));
          }
        }
      } catch (e) {
        // Silent fail for UX
      }
    });
  }
}
