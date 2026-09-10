import 'package:enterprise_flutter_app/core/config/app_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(dotenv.clean);

  test('builds API configuration from required environment values', () {
    dotenv.testLoad(
      fileInput: '''
API_BASE_URL=https://api.example.com/
API_VERSION=v1
REQUEST_TIMEOUT_SECONDS=45
''',
    );

    final config = AppConfig.fromDotEnv(
      environment: 'staging',
      debugMode: false,
    );

    expect(config.baseUrl, 'https://api.example.com');
    expect(config.apiVersion, 'v1');
    expect(config.requestTimeout, const Duration(seconds: 45));
    expect(config.environment, 'staging');
    expect(config.debugMode, isFalse);
  });

  test('rejects a missing required API value', () {
    dotenv.testLoad(
      fileInput: '''
API_BASE_URL=https://api.example.com
API_VERSION=v1
''',
    );

    expect(
      () => AppConfig.fromDotEnv(environment: 'development', debugMode: true),
      throwsStateError,
    );
  });

  test('rejects an API base URL with a path', () {
    dotenv.testLoad(
      fileInput: '''
API_BASE_URL=https://api.example.com/v1
API_VERSION=v1
REQUEST_TIMEOUT_SECONDS=30
''',
    );

    expect(
      () => AppConfig.fromDotEnv(environment: 'production', debugMode: false),
      throwsStateError,
    );
  });
}
