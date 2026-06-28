import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:enterprise_flutter_app/app/app.dart';
import 'package:enterprise_flutter_app/core/constants/app_constants.dart';
import 'package:enterprise_flutter_app/core/network/network_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await _initializeHive();

  // Check initial connectivity (outside ProviderScope, so we create a temp instance)
  await _checkInitialConnectivity();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

Future<void> _initializeHive() async {
  final directory = await getApplicationDocumentsDirectory();
  Hive.init(directory.path);

  // Open all required Hive boxes
  await Hive.openBox(AppConstants.authBox);
  await Hive.openBox(AppConstants.userBox);
  await Hive.openBox(AppConstants.settingsBox);
  await Hive.openBox(AppConstants.cacheBox);

  // Initialize default settings if first launch
  final settingsBox = Hive.box(AppConstants.settingsBox);
  if (settingsBox.get(AppConstants.appSettingsKey) == null) {
    await settingsBox.put(AppConstants.appSettingsKey, {
      'darkMode': true,
      'notificationsEnabled': true,
      'biometricEnabled': false,
      'language': 'en',
      'theme': 'dark',
      'autoSync': true,
      'analyticsEnabled': true,
      'fontSize': 'medium',
    });
  }
}

Future<void> _checkInitialConnectivity() async {
  try {
    final networkInfo = NetworkInfoImpl(Connectivity());
    final isConnected = await networkInfo.isConnected;
    debugPrint('Initial connectivity check: ${isConnected ? 'Online' : 'Offline'}');
  } catch (e) {
    debugPrint('Connectivity check failed: $e');
    // Silently ignore - the app will show offline banner if needed
  }
}
