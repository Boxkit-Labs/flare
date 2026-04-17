import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flare_app/core/error/failure.dart';
import 'package:flare_app/core/usecases/usecase.dart';
import 'package:flare_app/features/events/domain/entities/event_price_point_entity.dart';
import 'package:flare_app/features/events/domain/repositories/event_repository.dart';

class GetEventPriceHistoryUseCase implements UseCase<List<EventPricePointEntity>, GetEventPriceHistoryParams> {
  final EventRepository repository;

  GetEventPriceHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<EventPricePointEntity>>> call(GetEventPriceHistoryParams params) async {
    return await repository.getEventPriceHistory(params.platform, params.externalId);
  }
}

class GetEventPriceHistoryParams extends Equatable {
  final String platform;
  final String externalId;

  const GetEventPriceHistoryParams({
    required this.platform,
    required this.externalId,
  });

  @override
  List<Object?> get props => [platform, externalId];
}
