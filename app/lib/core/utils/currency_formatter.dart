import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class CurrencyFormatter {
  // Approximate exchange rates for USDC (pinned to 1.0 USD)
  static const Map<String, double> _usdcExchangeRates = {
    'USD': 1.0,
    'NGN': 1550.0,
    'GBP': 0.79,
    'EUR': 0.93,
    'CAD': 1.37,
    'JPY': 158.0,
    'AUD': 1.51,
    'INR': 83.50,
  };

  /// Formats an amount with the corresponding currency symbol and separators.
  static String formatCurrency(double amount, String currencyCode) {
    final format = NumberFormat.currency(
      symbol: getCurrencySymbol(currencyCode),
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    );
    return format.format(amount);
  }

  /// Handles min/max prices and the "Free" case.
  static String formatPriceRange(
    double? min,
    double? max, {
    bool isFree = false,
    String currency = 'USD',
  }) {
    if (isFree) return 'Free';
    if (min == null) return 'TBA';
    if (max == null || min == max) {
      return formatCurrency(min, currency);
    }
    return '${formatCurrency(min, currency)} - ${formatCurrency(max, currency)}';
  }

  /// Converts USDC amount to local currency and formats it.
  /// Never outputs "USDC" as the symbol.
  static String convertUsdcToLocal(double usdcAmount, String targetCurrency) {
    final rate =
        _usdcExchangeRates[targetCurrency.toUpperCase()] ??
        _usdcExchangeRates['USD']!;
    final localAmount = usdcAmount * rate;
    return formatCurrency(localAmount, targetCurrency);
  }

  /// Returns only the symbol for a given currency code.
  static String getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'NGN':
        return '₦';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'JPY':
        return '¥';
      case 'CAD':
        return r'C$';
      case 'AUD':
        return r'A$';
      case 'INR':
        return '₹';
      default:
        return currencyCode;
    }
  }

  /// Detects user currency based on device locale.
  /// Defaults to USD if no mapping is found.
  static String detectUserCurrency() {
    try {
      final locale = ui.PlatformDispatcher.instance.locale.countryCode
          ?.toUpperCase();

      final countryToCurrency = {
        'US': 'USD',
        'NG': 'NGN',
        'GB': 'GBP',
        'DE': 'EUR',
        'FR': 'EUR',
        'IT': 'EUR',
        'ES': 'EUR',
        'JP': 'JPY',
        'CA': 'CAD',
        'AU': 'AUD',
        'IN': 'INR',
      };

      return countryToCurrency[locale] ?? 'USD';
    } catch (_) {
      return 'USD';
    }
  }
}
