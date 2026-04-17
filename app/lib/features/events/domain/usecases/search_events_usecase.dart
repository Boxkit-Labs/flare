import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flare_app/core/error/failure.dart';
import 'package:flare_app/core/usecases/usecase.dart';
import 'package:flare_app/features/events/domain/entities/event_entity.dart';
import 'package:flare_app/features/events/domain/repositories/event_repository.dart';

class SearchEventsUseCase implements UseCase<List<EventEntity>, SearchEventsParams> {
  final EventRepository repository;

  SearchEventsUseCase(this.repository);

  @override
  Future<Either<Failure, List<EventEntity>>> call(SearchEventsParams params) async {
    return await repository.searchEvents(
      query: params.query,
      city: params.city,
      country: params.country,
      category: params.category,
      date: params.date,
      isFree: params.isFree,
      platform: params.platform,
      page: params.page,
      limit: params.limit,
    );
  }
}

class SearchEventsParams extends Equatable {
  final String? query;
  final String? city;
  final String? country;
  final String? category;
  final DateTime? date;
  final bool? isFree;
  final String? platform;
  final int? page;
  final int? limit;

  const SearchEventsParams({
    this.query,
    this.city,
    this.country,
    this.category,
    this.date,
    this.isFree,
    this.platform,
    this.page,
    this.limit,
  });

  @override
  List<Object?> get props => [query, city, country, category, date, isFree, platform, page, limit];
}
