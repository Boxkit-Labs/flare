import 'package:equatable/equatable.dart';

class EventWatcherParamsEntity extends Equatable {
  final String mode;
  final String? externalId;
  final String platform;
  final String? eventName;
  final dynamic watchTiers;
  final String? query;
  final String? city;
  final String? country;
  final String? category;
  final DateTime? eventDate;
  final bool? isFree;

  const EventWatcherParamsEntity({
    required this.mode,
    this.externalId,
    required this.platform,
    this.eventName,
    this.watchTiers = 'all',
    this.query,
    this.city,
    this.country,
    this.category,
    this.eventDate,
    this.isFree,
  });

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'externalId': externalId,
      'platform': platform,
      'eventName': eventName,
      'watchTiers': watchTiers,
      'query': query,
      'city': city,
      'country': country,
      'category': category,
      'eventDate': eventDate?.toIso8601String(),
      'isFree': isFree,
    };
  }

  factory EventWatcherParamsEntity.fromJson(Map<String, dynamic> json) {
    return EventWatcherParamsEntity(
      mode: json['mode'] as String,
      externalId: json['externalId'] as String?,
      platform: json['platform'] as String,
      eventName: json['eventName'] as String?,
      watchTiers: json['watchTiers'] as bool? ?? false,
      query: json['query'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      category: json['category'] as String?,
      eventDate: json['eventDate'] != null
          ? DateTime.parse(json['eventDate'] as String)
          : null,
      isFree: json['isFree'] as bool?,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        externalId,
        platform,
        eventName,
        watchTiers,
        query,
        city,
        country,
        category,
        eventDate,
        isFree,
      ];
}
