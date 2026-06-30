import 'package:enterprise_flutter_app/core/config/app_config.dart';
import 'package:enterprise_flutter_app/main_common.dart';

/// Production flavor entry point
/// Run with: flutter run -t lib/main_production.dart
/// Build with: flutter build apk -t lib/main_production.dart --release
void main() => mainCommon(AppConfig.production);
