import 'package:dio/dio.dart';
import 'package:flare_app/features/events/data/models/event_model.dart';
import 'package:flare_app/features/events/data/models/event_price_point_model.dart';

abstract class EventRemoteDataSource {
  Future<List<EventModel>> searchEvents({
    String? query,
    String? city,
    String? country,
    String? category,
    DateTime? date,
    bool? isFree,
    String? platform,
  });

  Future<EventModel> getEventDetail(String platform, String externalId);

  Future<List<String>> getPlatforms();

  Future<List<String>> getCategories();

  Future<List<String>> getCountries();

  Future<List<EventPricePointModel>> getEventPriceHistory(String platform, String externalId);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final Dio dio;

  EventRemoteDataSourceImpl(this.dio);

  @override
  Future<List<EventModel>> searchEvents({
    String? query,
    String? city,
    String? country,
    String? category,
    DateTime? date,
    bool? isFree,
    String? platform,
  }) async {
    final response = await dio.get(
      '/api/events/search',
      queryParameters: {
        if (query != null) 'q': query,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
        if (category != null) 'category': category,
        if (date != null) 'dateFrom': date.toIso8601String(),
        if (isFree != null) 'isFree': isFree.toString(),
        if (platform != null) 'platform': platform,
      },
    );

    final list = response.data as List;
    return list.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<EventModel> getEventDetail(String platform, String externalId) async {
    final response = await dio.get('/api/events/events/$platform/$externalId');
    return EventModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<String>> getPlatforms() async {
    final response = await dio.get('/api/events/platforms');
    final list = response.data as List;
    return list.cast<String>();
  }

  @override
  Future<List<String>> getCategories() async {
    final response = await dio.get('/api/events/categories');
    final list = response.data as List;
    return list.map((c) => (c as Map<String, dynamic>)['name'] as String).toList();
  }

  @override
  Future<List<String>> getCountries() async {
    final response = await dio.get('/api/events/countries');
    final list = response.data as List;
    return list.cast<String>();
  }

  @override
  Future<List<EventPricePointModel>> getEventPriceHistory(String platform, String externalId) async {
    final response = await dio.get('/api/events/events/$platform/$externalId/history');
    final list = response.data as List;
    return list.map((e) => EventPricePointModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
