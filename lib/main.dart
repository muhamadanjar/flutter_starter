import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:enterprise_flutter_app/app/app.dart';
import 'package:enterprise_flutter_app/core/constants/app_constants.dart';
import 'package:enterprise_flutter_app/core/network/network_info.dart';
import 'package:enterprise_flutter_app/core/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await _initializeHive();

  // Initialize Firebase for push notifications
  await _initializeFirebase();

  // Check initial connectivity (outside ProviderScope, so we create a temp instance)
  await _checkInitialConnectivity();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

Future<void> _initializeHive() async {
  // initFlutter() handles both web and mobile platforms automatically
  await Hive.initFlutter();

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

Future<void> _initializeFirebase() async {
  try {
    final firebaseService = FirebaseService();
    await firebaseService.initialize();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Continue app execution even if Firebase fails to initialize
    // This allows offline-only mode or graceful degradation
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
