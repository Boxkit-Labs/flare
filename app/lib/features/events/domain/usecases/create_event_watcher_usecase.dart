import 'package:dartz/dartz.dart';
import 'package:flare_app/core/error/failure.dart';
import 'package:flare_app/core/usecases/usecase.dart';
import 'package:flare_app/features/events/domain/entities/event_watcher_params_entity.dart';
import 'package:flare_app/features/watchers/domain/repositories/watcher_repository.dart';

class CreateEventWatcherUseCase implements UseCase<void, EventWatcherParamsEntity> {
  final WatcherRepository repository;

  CreateEventWatcherUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(EventWatcherParamsEntity params) async {
    // Client-side validation
    final validationError = _validate(params);
    if (validationError != null) {
      return Left(ValidationFailure(validationError));
    }

    return await repository.createWatcher(params);
  }

  String? _validate(EventWatcherParamsEntity params) {
    if (params.mode == 'specific_event') {
      if (params.externalId == null || params.externalId!.isEmpty) {
        return 'External ID is required for specific event monitoring';
      }
      if (params.platform.isEmpty) {
        return 'Platform is required for specific event monitoring';
      }
    } else if (params.mode == 'search') {
      if (params.query == null && 
          params.city == null && 
          params.category == null && 
          params.country == null) {
        return 'At least one search parameter (query, city, category, or country) is required';
      }
    } else {
      return 'Invalid watcher mode';
    }
    return null;
  }
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
