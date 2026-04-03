import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_app/services/api_service.dart';
import 'findings_event.dart';
import 'findings_state.dart';

class FindingsBloc extends Bloc<FindingsEvent, FindingsState> {
  final ApiService apiService;

  FindingsBloc(this.apiService) : super(FindingsInitial()) {
    on<LoadFindings>((event, emit) async {
      emit(FindingsLoading());
      try {
        final findings = await apiService.getFindings(
          event.userId,
          limit: event.limit,
          offset: event.offset,
        );
        final unreadCount = findings.where((f) => !f.isRead).length;
        emit(FindingsLoaded(findings, unreadCount));
      } catch (e) {
        emit(FindingsError(e.toString()));
      }
    });

    on<MarkFindingAsRead>((event, emit) async {
      try {
        await apiService.markFindingRead(event.findingId);
        // Refresh findings
        if (apiService.userId != null) {
          add(LoadFindings(apiService.userId!));
        }
      } catch (e) {
        emit(FindingsError(e.toString()));
      }
    });

    on<LoadFindingDetail>((event, emit) async {
      emit(FindingsLoading());
      try {
        final finding = await apiService.getFinding(event.findingId);
        emit(FindingDetailLoaded(finding));
      } catch (e) {
        emit(FindingsError(e.toString()));
      }
    });
  }
}
