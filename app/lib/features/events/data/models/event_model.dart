import 'package:flare_app/features/events/data/models/ticket_tier_model.dart';
import 'package:flare_app/features/events/domain/entities/event_entity.dart';

class EventModel extends EventEntity {
  const EventModel({
    required super.externalId,
    required super.platform,
    required super.name,
    super.description,
    required super.category,
    required super.date,
    super.endDate,
    required super.venue,
    super.venueAddress,
    required super.city,
    required super.country,
    super.latitude,
    super.longitude,
    super.imageUrl,
    required super.eventUrl,
    super.popularity,
    required super.isFree,
    required List<TicketTierModel> super.tiers,
    required super.currency,
    required super.status,
    required super.lastChecked,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      externalId: json['externalId'] as String,
      platform: json['platform'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      venue: json['venue'] as String,
      venueAddress: json['venueAddress'] as String?,
      city: json['city'] as String,
      country: json['country'] as String,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      imageUrl: json['imageUrl'] as String?,
      eventUrl: json['eventUrl'] as String,
      popularity: json['popularity'] != null ? (json['popularity'] as num).toDouble() : null,
      isFree: json['isFree'] as bool,
      tiers: (json['ticketTiers'] as List?)
              ?.map((t) => TicketTierModel.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      currency: json['currency'] as String,
      status: json['status'] as String,
      lastChecked: DateTime.parse(json['lastChecked'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'externalId': externalId,
      'platform': platform,
      'name': name,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'venue': venue,
      'venueAddress': venueAddress,
      'city': city,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'eventUrl': eventUrl,
      'popularity': popularity,
      'isFree': isFree,
      'ticketTiers': (tiers as List<TicketTierModel>).map((t) => t.toJson()).toList(),
      'currency': currency,
      'status': status,
      'lastChecked': lastChecked.toIso8601String(),
    };
  }
}
