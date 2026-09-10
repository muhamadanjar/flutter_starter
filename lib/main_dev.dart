import 'package:enterprise_flutter_app/main_common.dart';

/// Development flavor entry point
/// Run with: flutter run -t lib/main_dev.dart
Future<void> main() => mainCommon(
  environment: 'development',
  debugMode: true,
  envFile: '.env.dev',
);
