import 'package:dartz/dartz.dart';
import 'package:flare_app/core/error/exceptions.dart';
import 'package:flare_app/core/error/failure.dart';
import 'package:flare_app/features/events/domain/entities/event_watcher_params_entity.dart';
import 'package:flare_app/features/watchers/data/datasources/watcher_remote_data_source.dart';
import 'package:flare_app/features/watchers/domain/repositories/watcher_repository.dart';

class WatcherRepositoryImpl implements WatcherRepository {
  final WatcherRemoteDataSource remoteDataSource;

  WatcherRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, void>> createWatcher(EventWatcherParamsEntity params) async {
    try {
      await remoteDataSource.createWatcher(params);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred while creating watcher'));
    }
  }
}
