/// Application-wide constants
class AppConstants {
  AppConstants._();

  // Use 10.0.2.2 for Android emulator, or your machine's LAN IP for physical devices
  static const String apiBaseUrl = 'http://172.20.10.2:3000';
  static const String stellarExplorerUrl =
      'https://stellar.expert/explorer/testnet/tx/';
}
