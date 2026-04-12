class AppConstants {
  AppConstants._();
  static const String apiBaseUrl = 'https://flare-f9yk.onrender.com';
  static const String stellarExplorerUrl =
      'https://stellar.expert/explorer/testnet/tx/';

  static String get baseWsUrl {
    if (apiBaseUrl.contains('onrender.com')) {
      return 'wss://flare-f9yk.onrender.com';
    }
    return 'ws://10.0.2.2:4000';
  }
}
