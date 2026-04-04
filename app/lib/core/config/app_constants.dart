/// Application-wide constants
class AppConstants {
  AppConstants._();

  // Use 10.0.2.2 for Android emulator, or your machine's LAN IP for physical devices
  static const String apiBaseUrl = bool.fromEnvironment('PRODUCTION')
      ? 'https://flare-f9yk.onrender.com'
      : 'http://10.0.2.2:3000';
  static const String stellarExplorerUrl =
      'https://stellar.expert/explorer/testnet/tx/';
}
