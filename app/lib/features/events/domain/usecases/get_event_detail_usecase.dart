import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flare_app/core/error/failure.dart';
import 'package:flare_app/core/usecases/usecase.dart';
import 'package:flare_app/features/events/domain/entities/event_entity.dart';
import 'package:flare_app/features/events/domain/repositories/event_repository.dart';

class GetEventDetailUseCase implements UseCase<EventEntity, GetEventDetailParams> {
  final EventRepository repository;

  GetEventDetailUseCase(this.repository);

  @override
  Future<Either<Failure, EventEntity>> call(GetEventDetailParams params) async {
    return await repository.getEventDetail(params.platform, params.externalId);
  }
}

class GetEventDetailParams extends Equatable {
  final String platform;
  final String externalId;

  const GetEventDetailParams({
    required this.platform,
    required this.externalId,
  });

  @override
  List<Object?> get props => [platform, externalId];
}
