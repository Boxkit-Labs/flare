import 'package:equatable/equatable.dart';
import 'package:flare_app/core/models/models.dart';

abstract class WatchersState extends Equatable {
  const WatchersState();

  @override
  List<Object?> get props => [];
}

class WatchersInitial extends WatchersState {}

class WatchersLoading extends WatchersState {}

class WatchersLoaded extends WatchersState {
  final List<WatcherModel> watchers;
  const WatchersLoaded(this.watchers);

  @override
  List<Object?> get props => [watchers];
}

class WatcherDetailLoaded extends WatchersState {
  final WatcherModel watcher;
  const WatcherDetailLoaded(this.watcher);

  @override
  List<Object?> get props => [watcher];
}

class WatchersError extends WatchersState {
  final String message;
  const WatchersError(this.message);

  @override
  List<Object?> get props => [message];
}

class WatcherActionSuccess extends WatchersState {
  final String message;
  const WatcherActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
