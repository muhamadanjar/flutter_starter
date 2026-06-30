class AppConfig {
  final String baseUrl;
  final String apiVersion;
  final String environment;
  final bool debugMode;
  final Duration requestTimeout;

  const AppConfig({
    required this.baseUrl,
    required this.apiVersion,
    required this.environment,
    required this.debugMode,
    this.requestTimeout = const Duration(seconds: 30),
  });

  /// Development environment (local)
  static const dev = AppConfig(
    baseUrl: 'http://localhost:3000/api',
    apiVersion: 'v1',
    environment: 'development',
    debugMode: true,
  );

  /// Staging environment
  static const staging = AppConfig(
    baseUrl: 'https://staging-api.example.com/api',
    apiVersion: 'v1',
    environment: 'staging',
    debugMode: false,
  );

  /// Production environment
  static const production = AppConfig(
    baseUrl: 'https://api.example.com/api',
    apiVersion: 'v1',
    environment: 'production',
    debugMode: false,
  );

  /// Factory constructor to get config by flavor name
  factory AppConfig.fromFlavor(String flavor) {
    switch (flavor.toLowerCase()) {
      case 'dev':
      case 'development':
        return dev;
      case 'staging':
        return staging;
      case 'prod':
      case 'production':
        return production;
      default:
        return dev;
    }
  }

  @override
  String toString() => 'AppConfig(env: $environment, url: $baseUrl)';
}
