import 'package:equatable/equatable.dart';

abstract class WatchersEvent extends Equatable {
  const WatchersEvent();
  @override
  List<Object?> get props => [];
}

class LoadWatchers extends WatchersEvent {
  final String userId;
  const LoadWatchers(this.userId);
  @override
  List<Object?> get props => [userId];
}

class CreateWatcher extends WatchersEvent {
  final Map<String, dynamic> watcherData;
  const CreateWatcher(this.watcherData);
  @override
  List<Object?> get props => [watcherData];
}

class UpdateWatcher extends WatchersEvent {
  final String watcherId;
  final Map<String, dynamic> fields;
  const UpdateWatcher(this.watcherId, this.fields);
  @override
  List<Object?> get props => [watcherId, fields];
}

class ToggleWatcher extends WatchersEvent {
  final String watcherId;
  const ToggleWatcher(this.watcherId);
  @override
  List<Object?> get props => [watcherId];
}

class DeleteWatcher extends WatchersEvent {
  final String watcherId;
  const DeleteWatcher(this.watcherId);
  @override
  List<Object?> get props => [watcherId];
}

class LoadWatcherDetail extends WatchersEvent {
  final String watcherId;
  const LoadWatcherDetail(this.watcherId);
  @override
  List<Object?> get props => [watcherId];
}
