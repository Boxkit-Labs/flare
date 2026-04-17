import 'package:equatable/equatable.dart';

abstract class EventSearchEvent extends Equatable {
  const EventSearchEvent();

  @override
  List<Object?> get props => [];
}

class LoadInitialEvents extends EventSearchEvent {}

class SearchEvents extends EventSearchEvent {}

class UpdateQuery extends EventSearchEvent {
  final String query;
  const UpdateQuery(this.query);

  @override
  List<Object?> get props => [query];
}

class UpdateCity extends EventSearchEvent {
  final String? city;
  const UpdateCity(this.city);

  @override
  List<Object?> get props => [city];
}

class UpdateCountry extends EventSearchEvent {
  final String? country;
  const UpdateCountry(this.country);

  @override
  List<Object?> get props => [country];
}

class UpdateCategory extends EventSearchEvent {
  final String? category;
  const UpdateCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class UpdatePlatform extends EventSearchEvent {
  final String? platform;
  const UpdatePlatform(this.platform);

  @override
  List<Object?> get props => [platform];
}

class UpdatePriceRange extends EventSearchEvent {
  final double? min;
  final double? max;
  const UpdatePriceRange(this.min, this.max);

  @override
  List<Object?> get props => [min, max];
}

class ToggleFreeOnly extends EventSearchEvent {}

class UpdateDateRange extends EventSearchEvent {
  final DateTime? date;
  const UpdateDateRange(this.date);

  @override
  List<Object?> get props => [date];
}

class ClearFilters extends EventSearchEvent {}

class LoadMoreResults extends EventSearchEvent {}
