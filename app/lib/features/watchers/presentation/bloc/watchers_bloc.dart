import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_app/services/api_service.dart';
import 'watchers_event.dart';
import 'watchers_state.dart';

class WatchersBloc extends Bloc<WatchersEvent, WatchersState> {
  final ApiService apiService;

  WatchersBloc(this.apiService) : super(WatchersInitial()) {
    on<LoadWatchers>((event, emit) async {
      emit(WatchersLoading());
      try {
        final watchers = await apiService.getWatchers(event.userId);
        emit(WatchersLoaded(watchers));
      } catch (e) {
        emit(WatchersError(e.toString()));
      }
    });

    on<CreateWatcher>((event, emit) async {
      emit(WatchersLoading());
      try {
        await apiService.createWatcher(event.watcherData);
        emit(const WatcherActionSuccess('Watcher created successfully'));
        // Trigger reload
        if (apiService.userId != null) {
          add(LoadWatchers(apiService.userId!));
        }
      } catch (e) {
        emit(WatchersError(e.toString()));
      }
    });

    on<UpdateWatcher>((event, emit) async {
      emit(WatchersLoading());
      try {
        await apiService.updateWatcher(event.watcherId, event.fields);
        emit(const WatcherActionSuccess('Watcher updated successfully'));
        if (apiService.userId != null) {
          add(LoadWatchers(apiService.userId!));
        }
      } catch (e) {
        emit(WatchersError(e.toString()));
      }
    });

    on<ToggleWatcher>((event, emit) async {
      try {
        await apiService.toggleWatcher(event.watcherId);
        if (apiService.userId != null) {
          add(LoadWatchers(apiService.userId!));
        }
      } catch (e) {
        emit(WatchersError(e.toString()));
      }
    });

    on<DeleteWatcher>((event, emit) async {
      emit(WatchersLoading());
      try {
        await apiService.deleteWatcher(event.watcherId);
        emit(const WatcherActionSuccess('Watcher deleted successfully'));
        if (apiService.userId != null) {
          add(LoadWatchers(apiService.userId!));
        }
      } catch (e) {
        emit(WatchersError(e.toString()));
      }
    });

    on<LoadWatcherDetail>((event, emit) async {
      emit(WatchersLoading());
      try {
        final watcher = await apiService.getWatcher(event.watcherId);
        emit(WatcherDetailLoaded(watcher));
      } catch (e) {
        emit(WatchersError(e.toString()));
      }
    });
  }
}
