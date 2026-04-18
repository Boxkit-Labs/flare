import 'package:dartz/dartz.dart';
import 'package:flare_app/core/error/exceptions.dart';
import 'package:flare_app/core/error/failure.dart';
import 'package:flare_app/features/events/data/datasources/event_remote_data_source.dart';
import 'package:flare_app/features/events/domain/entities/event_entity.dart';
import 'package:flare_app/features/events/domain/entities/event_price_point_entity.dart';
import 'package:flare_app/features/events/domain/repositories/event_repository.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource remoteDataSource;

  // In-memory caching
  List<String>? _cachedPlatforms;
  List<String>? _cachedCategories;
  List<String>? _cachedCountries;

  // Search cache: key is a string representation of params, value is (timestamp, results)
  final Map<String, (DateTime, List<EventEntity>)> _searchCache = {};
  static const _cacheDuration = Duration(minutes: 5);

  EventRepositoryImpl(this.remoteDataSource);

  @override
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
  }) async {
    final cacheKey = '$query|$city|$country|$category|$date|$isFree|$platform|$page|$limit';
    
    if (_searchCache.containsKey(cacheKey)) {
      final (timestamp, results) = _searchCache[cacheKey]!;
      if (DateTime.now().difference(timestamp) < _cacheDuration) {
        return Right(results);
      }
    }

    try {
      final results = await remoteDataSource.searchEvents(
        query: query,
        city: city,
        country: country,
        category: category,
        date: date,
        isFree: isFree,
        platform: platform,
        page: page,
        limit: limit,
      );
      print('✅ SUCCESS in searchEvents: Found ${results.length} events');
      _searchCache[cacheKey] = (DateTime.now(), results);
      return Right(results);
    } on RateLimitException catch (e) {
      print('⚠️ RATE LIMIT ERROR in searchEvents: ${e.message}');
      return Left(ServerFailure('${e.message}. System will retry in 5 minutes.'));
    } on AppException catch (e) {
      print('❌ API ERROR in searchEvents: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e, stackTrace) {
      print('🔥 UNEXPECTED ERROR in searchEvents: $e\n$stackTrace');
      return const Left(ServerFailure('An unexpected error occurred during search'));
    }
  }

  @override
  Future<Either<Failure, EventEntity>> getEventDetail(String platform, String externalId) async {
    try {
      final result = await remoteDataSource.getEventDetail(platform, externalId);
      print('✅ SUCCESS in getEventDetail: Fetched details for $externalId on $platform');
      return Right(result);
    } on AppException catch (e) {
      print('❌ API ERROR in getEventDetail: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e, stackTrace) {
      print('🔥 UNEXPECTED ERROR in getEventDetail: $e\n$stackTrace');
      return const Left(ServerFailure('An unexpected error occurred while fetching event details'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getPlatforms() async {
    if (_cachedPlatforms != null) return Right(_cachedPlatforms!);
    try {
      final result = await remoteDataSource.getPlatforms();
      print('✅ SUCCESS in getPlatforms: Fetched ${result.length} platforms');
      _cachedPlatforms = result;
      return Right(result);
    } on AppException catch (e) {
      print('❌ API ERROR in getPlatforms: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e, stackTrace) {
      print('🔥 UNEXPECTED ERROR in getPlatforms: $e\n$stackTrace');
      return const Left(ServerFailure('An unexpected error occurred while fetching platforms'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getCategories() async {
    if (_cachedCategories != null) return Right(_cachedCategories!);
    try {
      final result = await remoteDataSource.getCategories();
      print('✅ SUCCESS in getCategories: Fetched ${result.length} categories');
      _cachedCategories = result;
      return Right(result);
    } on AppException catch (e) {
      print('❌ API ERROR in getCategories: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e, stackTrace) {
      print('🔥 UNEXPECTED ERROR in getCategories: $e\n$stackTrace');
      return const Left(ServerFailure('An unexpected error occurred while fetching categories'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getCountries() async {
    if (_cachedCountries != null) return Right(_cachedCountries!);
    try {
      final result = await remoteDataSource.getCountries();
      print('✅ SUCCESS in getCountries: Fetched ${result.length} countries');
      _cachedCountries = result;
      return Right(result);
    } on AppException catch (e) {
      print('❌ API ERROR in getCountries: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e, stackTrace) {
      print('🔥 UNEXPECTED ERROR in getCountries: $e\n$stackTrace');
      return const Left(ServerFailure('An unexpected error occurred while fetching countries'));
    }
  }

  @override
  Future<Either<Failure, List<EventPricePointEntity>>> getEventPriceHistory(String platform, String externalId) async {
    try {
      final result = await remoteDataSource.getEventPriceHistory(platform, externalId);
      print('✅ SUCCESS in getEventPriceHistory: Fetched ${result.length} price points for $externalId on $platform');
      return Right(result);
    } on AppException catch (e) {
      print('❌ API ERROR in getEventPriceHistory: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e, stackTrace) {
      print('🔥 UNEXPECTED ERROR in getEventPriceHistory: $e\n$stackTrace');
      return const Left(ServerFailure('An unexpected error occurred while fetching price history'));
    }
  }
}
