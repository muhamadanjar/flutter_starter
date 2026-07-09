import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../features/profile/presentation/providers/profile_provider.dart';
import '../constants/app_constants.dart';
import '../services/fcm_sync_service.dart';
import '../storage/preferences/index.dart';
import 'firebase_provider.dart';

final fcmSyncServiceProvider = Provider<FcmSyncService>((ref) {
  final service = FcmSyncService(
    firebaseService: ref.watch(firebaseServiceProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
    userPref: ref.watch(userPrefProvider),
    // Read Hive directly to avoid a dependency cycle with the auth feature.
    isLoggedIn: () async =>
        Hive.box(AppConstants.authBox).get(AppConstants.isLoggedInKey) as bool? ?? false,
  );
  ref.onDispose(service.dispose);
  return service;
});
