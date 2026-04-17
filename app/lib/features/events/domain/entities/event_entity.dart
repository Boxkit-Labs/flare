import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:flare_app/core/utils/currency_formatter.dart';
import 'ticket_tier_entity.dart';

class EventEntity extends Equatable {
  final String externalId;
  final String platform;
  final String name;
  final String? description;
  final String category;
  final DateTime date;
  final DateTime? endDate;
  final String venue;
  final String? venueAddress;
  final String city;
  final String country;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String eventUrl;
  final double? popularity;
  final bool isFree;
  final List<TicketTierEntity> tiers;
  final String currency;
  final String status;
  final DateTime lastChecked;

  const EventEntity({
    required this.externalId,
    required this.platform,
    required this.name,
    this.description,
    required this.category,
    required this.date,
    this.endDate,
    required this.venue,
    this.venueAddress,
    required this.city,
    required this.country,
    this.latitude,
    this.longitude,
    this.imageUrl,
    required this.eventUrl,
    this.popularity,
    required this.isFree,
    required this.tiers,
    required this.currency,
    required this.status,
    required this.lastChecked,
  });

  String get formattedLowestPrice {
    if (isFree) return 'Free';
    if (tiers.isEmpty) return 'TBA';
    final lowest = tiers
        .where((t) => t.available)
        .map((t) => t.minPrice)
        .fold<double?>(null, (prev, curr) => prev == null || curr < prev ? curr : prev);
    
    if (lowest == null) return 'Sold Out';
    return CurrencyFormatter.formatCurrency(lowest, currency);
  }

  String get priceRangeString {
    if (isFree) return 'Free';
    if (tiers.isEmpty) return 'TBA';
    
    final prices = tiers.map((t) => t.minPrice).toList() + tiers.map((t) => t.maxPrice).toList();
    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);

    return CurrencyFormatter.formatPriceRange(min, max, currency: currency);
  }

  String get ticketsAvailability {
    if (status.toLowerCase() == 'cancelled') return 'Sold Out';
    final anyAvailable = tiers.any((t) => t.available);
    if (!anyAvailable) return 'Sold Out';

    final hasLimited = tiers.any((t) => t.available && t.quantityRemaining != null && t.quantityRemaining! <= 10);
    
    if (hasLimited) return 'Limited';
    return 'Available';
  }

  String get formattedDate {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String get formattedFullDate {
    return DateFormat('EEEE, MMM d, yyyy • HH:mm').format(date);
  }

  String get platformDisplayName {
    switch (platform.toLowerCase()) {
      case 'ticketmaster':
        return 'Ticketmaster';
      case 'eventbrite':
        return 'Eventbrite';
      case 'skiddle':
        return 'Skiddle';
      case 'dice':
        return 'DICE';
      default:
        return platform[0].toUpperCase() + platform.substring(1);
    }
  }

  String get categoryEmoji {
    switch (category.toLowerCase()) {
      case 'music':
      case 'concert':
        return '🎵';
      case 'sport':
      case 'sports':
        return '🏆';
      case 'theatre':
      case 'arts':
        return '🎭';
      case 'comedy':
        return '😂';
      case 'nightlife':
      case 'club':
        return '💃';
      case 'festival':
        return '🎡';
      default:
        return '📅';
    }
  }

  bool get isPast => date.isBefore(DateTime.now());

  bool get isCancelled => status.toLowerCase() == 'cancelled';

  int get daysUntil {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }

  @override
  List<Object?> get props => [
        externalId,
        platform,
        name,
        description,
        category,
        date,
        endDate,
        venue,
        venueAddress,
        city,
        country,
        latitude,
        longitude,
        imageUrl,
        eventUrl,
        popularity,
        isFree,
        tiers,
        currency,
        status,
        lastChecked,
      ];
}
