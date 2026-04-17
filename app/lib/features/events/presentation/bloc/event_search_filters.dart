import 'package:equatable/equatable.dart';

class EventSearchFilters extends Equatable {
  final String? query;
  final String? city;
  final String? country;
  final String? category;
  final String? platform;
  final double? minPrice;
  final double? maxPrice;
  final bool isFreeOnly;
  final DateTime? date;

  const EventSearchFilters({
    this.query,
    this.city,
    this.country,
    this.category,
    this.platform,
    this.minPrice,
    this.maxPrice,
    this.isFreeOnly = false,
    this.date,
  });

  EventSearchFilters copyWith({
    String? query,
    String? city,
    String? country,
    String? category,
    String? platform,
    double? minPrice,
    double? maxPrice,
    bool? isFreeOnly,
    DateTime? date,
  }) {
    return EventSearchFilters(
      query: query ?? this.query,
      city: city ?? this.city,
      country: country ?? this.country,
      category: category ?? this.category,
      platform: platform ?? this.platform,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      isFreeOnly: isFreeOnly ?? this.isFreeOnly,
      date: date ?? this.date,
    );
  }

  @override
  List<Object?> get props => [
        query,
        city,
        country,
        category,
        platform,
        minPrice,
        maxPrice,
        isFreeOnly,
        date,
      ];
}
