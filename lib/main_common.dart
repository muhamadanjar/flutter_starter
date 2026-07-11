import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:enterprise_flutter_app/app/app.dart';
import 'package:enterprise_flutter_app/core/config/app_config.dart';
import 'package:enterprise_flutter_app/core/constants/app_constants.dart';
import 'package:enterprise_flutter_app/core/network/network_info.dart';
import 'package:enterprise_flutter_app/core/providers/config_provider.dart';
import 'package:enterprise_flutter_app/core/services/firebase_service.dart';
import 'package:enterprise_flutter_app/core/storage/preferences/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Common initialization logic for all flavors
Future<void> mainCommon(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await _initializeHive();

  // Initialize Firebase for push notifications
  await _initializeFirebase();

  // Check initial connectivity
  await _checkInitialConnectivity();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
      ],
      child: const App(),
    ),
  );
}

Future<void> _initializeHive() async {
  // initFlutter() handles both web and mobile platforms automatically
  await Hive.initFlutter();
  final userPref = UserPref();

  // Open all required Hive boxes
  await userPref.initBox();
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

Future<void> _initializeFirebase() async {
  try {
    final firebaseService = FirebaseService();
    await firebaseService.initialize();
    debugPrint('[Firebase] Initialized successfully');
  } catch (e) {
    debugPrint('[Firebase] Initialization failed: $e');
    // Continue app execution even if Firebase fails to initialize
    // This allows offline-only mode or graceful degradation
  }
}

Future<void> _checkInitialConnectivity() async {
  try {
    final networkInfo = NetworkInfoImpl(Connectivity());
    final isConnected = await networkInfo.isConnected;
    debugPrint('[Network] Initial connectivity check: ${isConnected ? 'Online' : 'Offline'}');
  } catch (e) {
    debugPrint('[Network] Connectivity check failed: $e');
    // Silently ignore - the app will show offline banner if needed
  }
}
