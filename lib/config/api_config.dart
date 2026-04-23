/// API base URL and compile-time toggles. See README for `USE_FAKE_LOCATIONS`.
class ApiConfig {
  ApiConfig._();

  static const bool useFakeLocations = bool.fromEnvironment(
    'USE_FAKE_LOCATIONS',
    defaultValue: false,
  );

  static String get defaultBaseUrl => 'https://api.kago.lelar.ge';
}
