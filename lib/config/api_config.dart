import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// API base URL and compile-time toggles. See README for `API_BASE_URL` / `USE_FAKE_LOCATIONS`.
class ApiConfig {
  ApiConfig._();

  static const bool useFakeLocations = bool.fromEnvironment(
    'USE_FAKE_LOCATIONS',
    defaultValue: false,
  );

  static String get defaultBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8787';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8787';
    }
    return 'http://127.0.0.1:8787';
  }
}
