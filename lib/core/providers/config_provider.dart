import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

/// App configuration provider
/// Override this in main() with the desired AppConfig
final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError(
    'appConfigProvider must be overridden in main()\n'
    'Example: appConfigProvider.overrideWithValue(AppConfig.production)',
  );
});
