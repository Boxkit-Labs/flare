import 'dart:ui' as ui;

class UserLocaleInfo {
  final String countryCode;
  final String currencyCode;
  final String defaultCity;
  final String defaultPlatform;
  final bool isNigerian;

  UserLocaleInfo({
    required this.countryCode,
    required this.currencyCode,
    required this.defaultCity,
    required this.defaultPlatform,
    this.isNigerian = false,
  });
}

class LocaleDetector {
  static UserLocaleInfo detect() {
    final locale = ui.PlatformDispatcher.instance.locale.countryCode?.toUpperCase() ?? 'US';
    
    if (locale == 'NG') {
      return UserLocaleInfo(
        countryCode: 'NG',
        currencyCode: 'NGN',
        defaultCity: 'Lagos',
        defaultPlatform: 'Eventbrite',
        isNigerian: true,
      );
    }

    if (locale == 'GB') {
        return UserLocaleInfo(
        countryCode: 'GB',
        currencyCode: 'GBP',
        defaultCity: 'London',
        defaultPlatform: 'Ticketmaster',
      );
    }
    
    // Default to US
    return UserLocaleInfo(
      countryCode: 'US',
      currencyCode: 'USD',
      defaultCity: 'New York',
      defaultPlatform: 'Ticketmaster',
    );
  }
}
