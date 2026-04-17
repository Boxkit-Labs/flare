import 'package:dio/dio.dart';
import 'package:flare_app/features/events/domain/entities/event_watcher_params_entity.dart';

abstract class WatcherRemoteDataSource {
  Future<void> createWatcher(EventWatcherParamsEntity params);
}

class WatcherRemoteDataSourceImpl implements WatcherRemoteDataSource {
  final Dio dio;

  WatcherRemoteDataSourceImpl(this.dio);

  @override
  Future<void> createWatcher(EventWatcherParamsEntity params) async {
    await dio.post('/api/watchers', data: params.toJson());
  }
}
