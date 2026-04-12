class AppConstants {
  AppConstants._();
  static const String apiBaseUrl = 'https://flare-f9yk.onrender.com';
  static const String stellarExplorerUrl =
      'https://stellar.expert/explorer/testnet/tx/';

  static String get baseWsUrl {
    final uri = Uri.parse(apiBaseUrl);
    final scheme = uri.isScheme('https') ? 'wss' : 'ws';
    final host = uri.host;
    final port = uri.hasPort ? ':${uri.port}' : '';
    
    return '$scheme://$host$port/ws/stream';
  }
}
