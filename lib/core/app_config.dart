class AppConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://localhost:8080', // Fallback
  );

  static const bool isProd = bool.fromEnvironment('IS_PROD');
  static const String appName = String.fromEnvironment('APP_NAME');
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const String sentryRelease = String.fromEnvironment(
    'SENTRY_RELEASE',
    defaultValue: 'tablemaster-mobile@local',
  );
  static const String _sentryTracesSampleRate = String.fromEnvironment(
    'SENTRY_TRACES_SAMPLE_RATE',
    defaultValue: '0.1',
  );
  static const bool sentryEnableStartupTestEvent = bool.fromEnvironment(
    'SENTRY_ENABLE_STARTUP_TEST_EVENT',
  );

  static final double sentryTracesSampleRate =
      double.tryParse(_sentryTracesSampleRate) ?? 0.1;
}
