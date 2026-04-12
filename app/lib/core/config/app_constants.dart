/// Application-wide constants
class AppConstants {
  AppConstants._();
  static const String apiBaseUrl = 'https://flare-f9yk.onrender.com';
  static const String stellarExplorerUrl =
      'https://stellar.expert/explorer/testnet/tx/';

  /// Returns the appropriate WebSocket URL based on the API environment.
  static String get baseWsUrl {
    if (apiBaseUrl.contains('onrender.com')) {
      // For Render, we might need a different port or the same one.
      // Assuming port 4000 is not exposed, we might need to fallback.
      // But for this project's current state, we'll try to guess.
      return 'wss://flare-f9yk.onrender.com';
    }
    
    // For local development on Android emulator
    return 'ws://10.0.2.2:4000';
  }
}
