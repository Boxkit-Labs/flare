import 'package:dartz/dartz.dart';
import 'package:flare_app/core/error/failure.dart';
import 'package:flare_app/core/usecases/usecase.dart';
import 'package:flare_app/features/events/domain/repositories/event_repository.dart';

class GetPlatformsUseCase implements UseCase<List<String>, NoParams> {
  final EventRepository repository;

  GetPlatformsUseCase(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) async {
    return await repository.getPlatforms();
  }
}
