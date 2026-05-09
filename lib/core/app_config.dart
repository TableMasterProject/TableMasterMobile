class AppConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://localhost:8080', // Fallback
  );

  static const bool isProd = bool.fromEnvironment('IS_PROD');
  static const String appName = String.fromEnvironment('APP_NAME');
}
