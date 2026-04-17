import 'package:dartz/dartz.dart';
import 'package:flare_app/core/error/failure.dart';
import 'package:flare_app/features/events/domain/entities/event_watcher_params_entity.dart';

abstract class WatcherRepository {
  Future<Either<Failure, void>> createWatcher(EventWatcherParamsEntity params);
}
