import 'package:dartz/dartz.dart';
import 'package:flare_app/core/error/failure.dart';
import 'package:flare_app/features/events/domain/entities/event_entity.dart';
import 'package:flare_app/features/events/domain/entities/event_price_point_entity.dart';

abstract class EventRepository {
  Future<Either<Failure, List<EventEntity>>> searchEvents({
    String? query,
    String? city,
    String? country,
    String? category,
    DateTime? date,
    bool? isFree,
    String? platform,
    int? page,
    int? limit,
  });

  Future<Either<Failure, EventEntity>> getEventDetail(String platform, String externalId);

  Future<Either<Failure, List<String>>> getPlatforms();

  Future<Either<Failure, List<String>>> getCategories();

  Future<Either<Failure, List<String>>> getCountries();

  Future<Either<Failure, List<EventPricePointEntity>>> getEventPriceHistory(String platform, String externalId);
}
