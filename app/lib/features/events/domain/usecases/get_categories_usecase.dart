import 'package:dartz/dartz.dart';
import 'package:flare_app/core/error/failure.dart';
import 'package:flare_app/core/usecases/usecase.dart';
import 'package:flare_app/features/events/domain/repositories/event_repository.dart';

class GetCategoriesUseCase implements UseCase<List<String>, NoParams> {
  final EventRepository repository;

  GetCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) async {
    return await repository.getCategories();
  }
}
