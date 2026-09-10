import 'package:enterprise_flutter_app/main_common.dart';

/// Staging flavor entry point
/// Run with: flutter run -t lib/main_staging.dart
Future<void> main() => mainCommon(
  environment: 'staging',
  debugMode: false,
  envFile: '.env.staging',
);
