import 'package:equatable/equatable.dart';
import 'package:flare_app/core/utils/currency_formatter.dart';
import 'package:flare_app/features/events/domain/entities/event_entity.dart';

enum EventWatchSubmissionStatus { initial, submitting, success, failure }

class EventWatchSetupState extends Equatable {
  final EventEntity? event;
  final Set<String> selectedTiers;
  final bool priceAlertEnabled;
  final double? priceBelow;
  final int? priceDropPercentage;
  final bool availabilityAlertEnabled;
  final bool almostSoldOutAlertEnabled;
  final Duration frequency;
  final EventWatchSubmissionStatus status;
  final String? errorMessage;
  final String userCurrency;

  const EventWatchSetupState({
    this.event,
    this.selectedTiers = const {},
    this.priceAlertEnabled = true,
    this.priceBelow,
    this.priceDropPercentage,
    this.availabilityAlertEnabled = true,
    this.almostSoldOutAlertEnabled = false,
    this.frequency = const Duration(hours: 1),
    this.status = EventWatchSubmissionStatus.initial,
    this.errorMessage,
    this.userCurrency = 'USD',
  });

  bool get isFreeEvent => event?.isFree ?? false;

  bool get canSetPriceAlert => !isFreeEvent;

  bool get isValid {
    if (event == null) return false;
    if (selectedTiers.isEmpty) return false;
    if (!priceAlertEnabled && !availabilityAlertEnabled && !almostSoldOutAlertEnabled) return false;
    return true;
  }

  /// Cost estimate calculated from 0.005 USDC per check.
  String get costEstimate {
    const usdcPerCheck = 0.005;
    final checksPerDay = (const Duration(hours: 24).inMinutes / frequency.inMinutes);
    final usdcPerDay = checksPerDay * usdcPerCheck;
    
    return CurrencyFormatter.convertUsdcToLocal(usdcPerDay, userCurrency);
  }

  EventWatchSetupState copyWith({
    EventEntity? event,
    Set<String>? selectedTiers,
    bool? priceAlertEnabled,
    double? priceBelow,
    int? priceDropPercentage,
    bool? availabilityAlertEnabled,
    bool? almostSoldOutAlertEnabled,
    Duration? frequency,
    EventWatchSubmissionStatus? status,
    String? errorMessage,
    String? userCurrency,
  }) {
    return EventWatchSetupState(
      event: event ?? this.event,
      selectedTiers: selectedTiers ?? this.selectedTiers,
      priceAlertEnabled: priceAlertEnabled ?? this.priceAlertEnabled,
      priceBelow: priceBelow ?? this.priceBelow,
      priceDropPercentage: priceDropPercentage ?? this.priceDropPercentage,
      availabilityAlertEnabled: availabilityAlertEnabled ?? this.availabilityAlertEnabled,
      almostSoldOutAlertEnabled: almostSoldOutAlertEnabled ?? this.almostSoldOutAlertEnabled,
      frequency: frequency ?? this.frequency,
      status: status ?? this.status,
      errorMessage: errorMessage,
      userCurrency: userCurrency ?? this.userCurrency,
    );
  }

  @override
  List<Object?> get props => [
        event,
        selectedTiers,
        priceAlertEnabled,
        priceBelow,
        priceDropPercentage,
        availabilityAlertEnabled,
        almostSoldOutAlertEnabled,
        frequency,
        status,
        errorMessage,
        userCurrency,
      ];
}
