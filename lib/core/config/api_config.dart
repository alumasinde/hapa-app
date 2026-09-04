import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const String defaultApiVersion = '/v1';

  // Development on a physical phone should use the laptop's LAN IP, not
  // 127.0.0.1/localhost. Override this with --dart-define for each network.
  static const String developmentHost = String.fromEnvironment(
    'HAPA_API_HOST',
    defaultValue: '192.168.100.11',
  );

  static const int developmentPort = int.fromEnvironment(
    'HAPA_API_PORT',
    defaultValue: 8000,
  );

  static String get baseUrl {
    if (kReleaseMode) {
      return const String.fromEnvironment(
        'HAPA_API_BASE_URL',
        defaultValue: 'https://api.example.com/v1',
      );
    }

    return 'http://$developmentHost:$developmentPort$defaultApiVersion';
  }
}
