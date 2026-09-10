import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  /// Creates API configuration from the environment file selected by a flavor.
  ///
  /// Missing or invalid values intentionally stop application startup. Falling
  /// back to an endpoint could send a user to the wrong environment.
  factory AppConfig.fromDotEnv({
    required String environment,
    required bool debugMode,
  }) {
    final baseUrl = _requiredValue('API_BASE_URL');
    final apiVersion = _requiredValue('API_VERSION');
    final timeoutSeconds = int.tryParse(
      _requiredValue('REQUEST_TIMEOUT_SECONDS'),
    );
    final uri = Uri.tryParse(baseUrl);

    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw StateError(
        'API_BASE_URL must be an HTTP(S) origin without a path, query, or '
        'fragment (for example, https://api.example.com).',
      );
    }
    if (timeoutSeconds == null || timeoutSeconds <= 0) {
      throw StateError('REQUEST_TIMEOUT_SECONDS must be a positive integer.');
    }

    return AppConfig(
      baseUrl: baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl,
      apiVersion: apiVersion,
      environment: environment,
      debugMode: debugMode,
      requestTimeout: Duration(seconds: timeoutSeconds),
    );
  }

  static String _requiredValue(String key) {
    final value = dotenv.maybeGet(key)?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('$key must be set in the selected environment file.');
    }
    return value;
  }

  @override
  String toString() => 'AppConfig(env: $environment, url: $baseUrl)';
}
