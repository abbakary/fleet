import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  final String apiBaseUrl;

  // Select proper base URL per platform (web/desktop/iOS use localhost; Android emulator uses 10.0.2.2)
  static AppConfig get current {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return AppConfig(apiBaseUrl: override.endsWith('/') ? override : '$override/');
    }
    if (kIsWeb) {
      return const AppConfig(apiBaseUrl: 'http://127.0.0.1:8000/api/');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const AppConfig(apiBaseUrl: 'http://10.0.2.2:8000/api/');
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return const AppConfig(apiBaseUrl: 'http://127.0.0.1:8000/api/');
    }
  }

  // Legacy constant for tests where platform is not available
  static const AppConfig dev = AppConfig(apiBaseUrl: 'http://10.0.2.2:8000/api/');
}
