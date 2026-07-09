# Graph Report - /home/anjar/Development/enterprise_flutter_app  (2026-07-10)

## Corpus Check
- 217 files · ~60,794 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1926 nodes · 2467 edges · 171 communities (111 shown, 60 thin omitted)
- Extraction: 97% EXTRACTED · 1% INFERRED · 1% AMBIGUOUS · INFERRED: 34 edges (avg confidence: 0.66)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Localization & i18n
- Theme & Styling
- Theme & Styling
- Localization & i18n
- Localization & i18n
- Authentication
- Authentication
- UI Widgets
- Theme & Styling
- Adaptive Widgets
- Network Layer
- Profile Feature
- Authentication
- Authentication
- Authentication
- Profile Feature
- Authentication
- Profile Feature
- Input Validators
- Settings Feature
- Authentication
- Authentication
- Theme & Styling
- Authentication
- UI Widgets
- Authentication
- UI Widgets
- Authentication
- Dashboard Feature
- Dashboard Feature
- Firebase & Push
- Dashboard Feature
- Settings Feature
- Logging System
- UI Widgets
- Theme & Styling
- Theme & Styling
- Input Validators
- Authentication
- Profile Feature
- Dashboard Feature
- Settings Feature
- Profile Feature
- Authentication
- Localization & i18n
- Theme & Styling
- Authentication
- Profile Feature
- Profile Feature
- Authentication
- Profile Feature
- Profile Feature
- Firebase & Push
- Theme & Styling
- Dashboard Feature
- Authentication
- Localization & i18n
- Localization & i18n
- macOS Platform
- Authentication
- Windows Platform
- Configuration & Constants
- Logging System
- Dashboard Feature
- Network Layer
- Authentication
- Profile Feature
- Theme & Styling
- Configuration & Constants
- Dashboard Feature
- Storage & Preferences
- Theme & Styling
- Theme & Styling
- Firebase & Push
- Dashboard Feature
- Settings Feature
- Theme & Styling
- Profile Feature
- Dashboard Feature
- Profile Feature
- Storage & Preferences
- Authentication
- iOS Platform
- Group 83
- Network Layer
- Authentication
- Localization & i18n
- UI Widgets
- UI Widgets
- Authentication
- Authentication
- Theme & Styling
- Profile Feature
- macOS Platform
- Authentication
- iOS Platform
- Profile Feature
- Localization & i18n
- Authentication
- Android Platform
- Authentication
- Storage & Preferences
- Authentication
- UI Widgets
- Authentication
- Android Platform
- Architecture Concepts
- macOS Platform
- Logging System
- Firebase & Push
- Architecture Concepts
- Architecture Concepts
- Localization & i18n
- Logging System
- Architecture Concepts
- Architecture Concepts
- Architecture Concepts
- App Entry Points
- iOS Platform
- Theme & Styling
- Authentication
- Profile Feature
- App Entry Points
- macOS Platform
- Group 127
- Group 128
- Group 129
- Configuration & Constants
- Firebase & Push
- Group 132
- Localization & i18n
- Group 134
- Group 135
- Group 136
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- App Icons
- Launch Images
- Launch Images
- Launch Images
- Group 170

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 22 edges
2. `authProvider` - 14 edges
3. `MessageHandler` - 12 edges
4. `profileProvider` - 10 edges
5. `FlutterWindow` - 10 edges
6. `Create` - 10 edges
7. `WndProc` - 10 edges
8. `Failure` - 9 edges
9. `MessageHandler` - 9 edges
10. `_AppState` - 8 edges

## Surprising Connections (you probably didn't know these)
- `initState` --references--> `authProvider`  [EXTRACTED]
  lib/app/app.dart → lib/features/auth/presentation/providers/auth_provider.dart
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  windows/runner/win32_window.cpp → windows/runner/win32_window.h
- `_AppState` --references--> `authProvider`  [EXTRACTED]
  lib/app/app.dart → lib/features/auth/presentation/providers/auth_provider.dart
- `createRouter` --references--> `authProvider`  [EXTRACTED]
  lib/app/router/app_router.dart → lib/features/auth/presentation/providers/auth_provider.dart

## Import Cycles
- None detected.

## Communities (171 total, 60 thin omitted)

### Community 0 - "Localization & i18n"
Cohesion: 0.03
Nodes (71): app_localizations_en.dart, app_localizations_id.dart, class, appDescription, appTitle, authConfirmPassword, authEmail, authForgotPassword (+63 more)

### Community 1 - "Theme & Styling"
Cohesion: 0.03
Nodes (65): AppColorScheme get, accent, accentContainer, accentDark, accentGradient, accentLight, AppColors, background (+57 more)

### Community 2 - "Theme & Styling"
Cohesion: 0.06
Nodes (53): PluginRegistry, Point, RECT, Size, unique_ptr, RegisterPlugins(), DartProject, HWND (+45 more)

### Community 3 - "Localization & i18n"
Cohesion: 0.03
Nodes (59): app_localizations.dart, appDescription, appTitle, authConfirmPassword, authEmail, authForgotPassword, authHaveAccount, authLogin (+51 more)

### Community 4 - "Localization & i18n"
Cohesion: 0.03
Nodes (58): appDescription, appTitle, authConfirmPassword, authEmail, authForgotPassword, authHaveAccount, authLogin, authLogout (+50 more)

### Community 5 - "Authentication"
Cohesion: 0.05
Nodes (38): ApiConstants, authMetas, baseUrl, changePassword, connectTimeout, dashboard, login, logout (+30 more)

### Community 6 - "Authentication"
Cohesion: 0.06
Nodes (34): ../../../../core/network/session_events.dart, ../../../../core/providers/fcm_sync_provider.dart, ../../../../core/services/fcm_sync_service.dart, ../../data/datasources/auth_local_datasource.dart, ../../data/datasources/auth_remote_datasource.dart, ../../data/repositories/auth_repository_impl.dart, ../../domain/usecases/login_usecase.dart, ../../domain/usecases/logout_usecase.dart (+26 more)

### Community 7 - "UI Widgets"
Cohesion: 0.06
Nodes (33): build, createState, customAllowedExtensions, errorMessage, FilePickerType, _fileUploadService, _getDefaultExtensions, _getFileName (+25 more)

### Community 8 - "Theme & Styling"
Cohesion: 0.06
Nodes (32): EdgeInsetsGeometry?, FocusNode?, FormFieldValidator, InputBorder?, border, build, contentPadding, controller (+24 more)

### Community 9 - "Adaptive Widgets"
Cohesion: 0.06
Nodes (32): alignment, baseStyle, build, child, childAspectRatio, children, desktopColumns, desktopPadding (+24 more)

### Community 10 - "Network Layer"
Cohesion: 0.07
Nodes (27): Connectivity, Future, _connectivity, isConnected, NetworkInfo, NetworkInfoImpl, networkInfoProvider, onConnectivityChanged (+19 more)

### Community 11 - "Profile Feature"
Cohesion: 0.06
Nodes (31): ../../../../core/logger/index.dart, ../../../../core/services/gps_service.dart, ../../data/datasources/profile_local_datasource.dart, ../../data/datasources/profile_remote_datasource.dart, ../../data/repositories/profile_repository_impl.dart, ../../domain/usecases/change_password_usecase.dart, ../../domain/usecases/get_profile_usecase.dart, ../../domain/usecases/update_profile_usecase.dart (+23 more)

### Community 12 - "Authentication"
Cohesion: 0.17
Nodes (27): Clean Architecture, Dio HTTP Client, Environment Configuration, Feature Module Structure, Firebase Push Notifications, Firebase Configuration, Environment Flavors, Freezed Code Generation (+19 more)

### Community 13 - "Authentication"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 14 - "Authentication"
Cohesion: 0.10
Nodes (23): ConsumerWidget, fcmTokenProvider, fcmTokenRefreshProvider, firebaseService, firebaseServiceProvider, getToken, subscribeToTopic, topicSubscriptionProvider (+15 more)

### Community 15 - "Profile Feature"
Cohesion: 0.10
Nodes (24): ../../../../core/widgets/avatar_upload_widget.dart, ../../../../core/widgets/custom_text_field.dart, FormState, build, _onChangePassword, build, _buildContent, createState (+16 more)

### Community 16 - "Authentication"
Cohesion: 0.10
Nodes (23): Exception, int?, CacheException, errorCode, fieldErrors, message, NetworkException, ServerException (+15 more)

### Community 17 - "Profile Feature"
Cohesion: 0.08
Nodes (24): ../../features/profile/data/datasources/profile_local_datasource.dart, ../../features/profile/data/datasources/profile_remote_datasource.dart, ../../features/profile/data/repositories/profile_repository_impl.dart, checkPermission, currentLocationProvider, getCurrentLocation, getLocationStream, gpsService (+16 more)

### Community 18 - "Input Validators"
Cohesion: 0.11
Nodes (24): FormzInput, ConfirmedPassword, confirmedPasswordError, ConfirmedPasswordValidationError, dirty, Email, emailError, _emailRegex (+16 more)

### Community 19 - "Settings Feature"
Cohesion: 0.08
Nodes (24): accuracy, altitude, calculateDistance, checkPermission, fromJson, fromPosition, getCurrentLocation, getLocationStream (+16 more)

### Community 20 - "Authentication"
Cohesion: 0.08
Nodes (23): AnimationController, _animationController, build, _buildDivider, _buildHeader, createState, dispose, _emailController (+15 more)

### Community 21 - "Authentication"
Cohesion: 0.08
Nodes (23): ChangeNotifier, ../../core/widgets/offline_banner.dart, ../../features/auth/presentation/pages/login_page.dart, ../../features/auth/presentation/pages/register_page.dart, ../../features/dashboard/presentation/pages/dashboard_page.dart, ../../features/profile/presentation/pages/change_password_page.dart, ../../features/profile/presentation/pages/profile_page.dart, ../../features/settings/presentation/pages/settings_page.dart (+15 more)

### Community 22 - "Theme & Styling"
Cohesion: 0.09
Nodes (21): ../../../../core/theme/app_colors.dart, ../../../../core/theme/app_typography.dart, ../../../../core/utils/date_formatter.dart, ../../domain/entities/dashboard.dart, fromJson, fromLocalJson, RecentActivityModel, toJson (+13 more)

### Community 23 - "Authentication"
Cohesion: 0.09
Nodes (22): Animation, _animationController, build, _buildHeader, _confirmedPassword, _confirmPasswordController, createState, dispose (+14 more)

### Community 24 - "UI Widgets"
Cohesion: 0.09
Nodes (22): EdgeInsets, build, _buildPlaceholder, createState, currentAvatarUrl, errorMessage, _fileUploadService, isLoading (+14 more)

### Community 25 - "Authentication"
Cohesion: 0.09
Nodes (22): accessToken, analyticsEnabled, autoSync, biometricEnabled, boxName, clearAll, clearAuth, darkMode (+14 more)

### Community 26 - "UI Widgets"
Cohesion: 0.09
Nodes (22): allowCamera, allowGallery, build, createState, errorMessage, _fileUploadService, _getFileName, _getFileSizeText (+14 more)

### Community 27 - "Authentication"
Cohesion: 0.09
Nodes (21): ../constants/api_constants.dart, Dio, ../errors/exceptions.dart, _authBox, _authInterceptor, _config, _dio, dioClientProvider (+13 more)

### Community 28 - "Dashboard Feature"
Cohesion: 0.10
Nodes (20): ../../data/datasources/dashboard_local_datasource.dart, ../../data/datasources/dashboard_remote_datasource.dart, ../../data/repositories/dashboard_repository_impl.dart, ../../domain/usecases/get_dashboard_usecase.dart, DashboardDataModel, DashboardData, copyWith, dashboardLocalDataSourceProvider (+12 more)

### Community 29 - "Dashboard Feature"
Cohesion: 0.10
Nodes (20): activeUsers, change, description, icon, id, label, orderGrowth, props (+12 more)

### Community 30 - "Firebase & Push"
Cohesion: 0.10
Nodes (19): FirebaseMessaging?, getInitialMessage, getToken, _handleForegroundMessage, _handleNotificationTap, initialize, _instance, _isInitialized (+11 more)

### Community 31 - "Dashboard Feature"
Cohesion: 0.13
Nodes (17): ../../../../core/constants/api_constants.dart, ../../../../core/network/dio_client.dart, ../../domain/dtos/meta_update_request.dart, DioClient, DashboardRemoteDataSource, DashboardRemoteDataSourceImpl, _dioClient, getDashboardData (+9 more)

### Community 32 - "Settings Feature"
Cohesion: 0.11
Nodes (18): ../../data/datasources/settings_local_datasource.dart, ../../data/repositories/settings_repository_impl.dart, ../../domain/usecases/get_settings_usecase.dart, ../../domain/usecases/update_settings_usecase.dart, copyWith, errorMessage, _getSettingsUseCase, getSettingsUseCaseProvider (+10 more)

### Community 33 - "Logging System"
Cohesion: 0.11
Nodes (18): close, d, e, i, _initLogger, _instance, log, _logger (+10 more)

### Community 34 - "UI Widgets"
Cohesion: 0.11
Nodes (18): borderRadius, build, _buildButton, _buildChild, _buildDangerButton, _buildGhostButton, _buildOutlineButton, _buildPrimaryButton (+10 more)

### Community 35 - "Theme & Styling"
Cohesion: 0.12
Nodes (16): ../../../../core/network/network_info.dart, custom_button.dart, IconData, isConnectedProvider, AppErrorWidget, build, icon, message (+8 more)

### Community 36 - "Theme & Styling"
Cohesion: 0.12
Nodes (17): ../../../../core/utils/validators.dart, ../../../../core/widgets/custom_button.dart, ChangePasswordPage, _ChangePasswordPageState, _confirmedPassword, _confirmPasswordController, createState, _currentPasswordController (+9 more)

### Community 37 - "Input Validators"
Cohesion: 0.11
Nodes (17): ImagePicker, FileUploadService, getFileName, getFileSize, getFileSizeInMB, getMimeType, _instance, isFileSizeValid (+9 more)

### Community 38 - "Authentication"
Cohesion: 0.15
Nodes (17): ConsumerState, ConsumerStatefulWidget, App, createRouter, _buildDesktopLayout, ShellWithNavigation, LoginPage, _LoginPageState (+9 more)

### Community 39 - "Profile Feature"
Cohesion: 0.12
Nodes (16): ../../features/profile/domain/dtos/index.dart, ../../features/profile/domain/repositories/profile_repository.dart, firebase_service.dart, detach, dispose, _firebaseService, metaKey, _profileRepository (+8 more)

### Community 40 - "Dashboard Feature"
Cohesion: 0.15
Nodes (15): ../../../../core/utils/extensions.dart, ../../../../core/widgets/adaptive_layout.dart, ../../../../core/widgets/error_widget.dart, ../../../../core/widgets/loading_widget.dart, build, _buildContent, createState, DashboardPage (+7 more)

### Community 41 - "Settings Feature"
Cohesion: 0.17
Nodes (13): ../entities/app_settings.dart, SettingsRepositoryImpl, getSettings, SettingsRepository, updateSettings, call, GetSettingsUseCase, _repository (+5 more)

### Community 42 - "Profile Feature"
Cohesion: 0.15
Nodes (13): ../entities/profile.dart, ProfileRepositoryImpl, ProfileRepository, call, ChangePasswordUseCase, _repository, call, GetProfileUseCase (+5 more)

### Community 43 - "Authentication"
Cohesion: 0.15
Nodes (13): ../entities/user.dart, AuthRepositoryImpl, AuthRepository, call, LoginUseCase, _repository, call, LogoutUseCase (+5 more)

### Community 44 - "Localization & i18n"
Cohesion: 0.13
Nodes (15): copyWith, defaultLocale, getLocaleForLanguage, locale, LocalizationNotifier, LocalizationState, setLocale, setLocaleFromLanguageCode (+7 more)

### Community 45 - "Theme & Styling"
Cohesion: 0.12
Nodes (15): AppTypography, bodyLarge, bodyMedium, bodySmall, buttonLarge, buttonMedium, buttonSmall, caption (+7 more)

### Community 46 - "Authentication"
Cohesion: 0.13
Nodes (15): _authBox, AuthLocalDataSource, AuthLocalDataSourceImpl, clearAll, getRefreshToken, getToken, getUser, getUserId (+7 more)

### Community 47 - "Profile Feature"
Cohesion: 0.12
Nodes (15): address, avatarUrl, bio, city, country, createdAt, dateOfBirth, email (+7 more)

### Community 48 - "Profile Feature"
Cohesion: 0.15
Nodes (13): Box, ../../../../core/constants/app_constants.dart, cacheProfile, getCachedProfile, ProfileLocalDataSource, ProfileLocalDataSourceImpl, _userBox, _defaultSettings (+5 more)

### Community 49 - "Authentication"
Cohesion: 0.13
Nodes (14): ../datasources/auth_local_datasource.dart, ../datasources/auth_remote_datasource.dart, ../../domain/repositories/auth_repository.dart, clearLocalSession, _getCachedUser, getProfile, getToken, isLoggedIn (+6 more)

### Community 50 - "Profile Feature"
Cohesion: 0.13
Nodes (14): ../datasources/profile_local_datasource.dart, ../datasources/profile_remote_datasource.dart, ../../domain/dtos/index.dart, ../../domain/repositories/profile_repository.dart, changePassword, _getCachedProfile, getMetas, getProfile (+6 more)

### Community 51 - "Profile Feature"
Cohesion: 0.13
Nodes (15): _ErrorPage, AdaptiveContainer, AdaptiveGrid, AdaptivePadding, AdaptiveSliverGrid, AdaptiveText, AdaptiveWrap, ScreenSizeVisibility (+7 more)

### Community 52 - "Firebase & Push"
Cohesion: 0.13
Nodes (14): accessTokenStreamProvider, biometricEnabledStreamProvider, darkModeStreamProvider, fcmTokenStreamProvider, fontSizeStreamProvider, initBox, initUserPrefProvider, isLoggedInStreamProvider (+6 more)

### Community 53 - "Theme & Styling"
Cohesion: 0.14
Nodes (13): ../../../auth/presentation/providers/auth_provider.dart, children, createState, icon, iconColor, onTap, _SettingsTile, _showAboutDialog (+5 more)

### Community 54 - "Dashboard Feature"
Cohesion: 0.14
Nodes (13): ../../core/widgets/responsive_builder.dart, build, build, _buildMobileLayout, _buildTabletLayout, child, currentIndex, _destinations (+5 more)

### Community 55 - "Authentication"
Cohesion: 0.22
Nodes (13): CacheFailure, errorCode, Failure, fieldErrors, message, NetworkFailure, props, ServerFailure (+5 more)

### Community 56 - "Localization & i18n"
Cohesion: 0.17
Nodes (10): ../app/router/app_router.dart, ../config/app_config.dart, ../../../../core/localization/localization_provider.dart, ../core/theme/app_theme.dart, ../../features/auth/presentation/providers/auth_provider.dart, ../features/settings/presentation/providers/settings_provider.dart, createState, initState (+2 more)

### Community 57 - "Localization & i18n"
Cohesion: 0.17
Nodes (11): AppLocalizations get, BuildContext, Iterable, ../../l10n/app_localizations.dart, BuildContextColors, firstWhereOrNull, IterableExtension, l10n (+3 more)

### Community 58 - "macOS Platform"
Cohesion: 0.21
Nodes (6): Cocoa, FlutterMacOS, RunnerTests, RunnerTests, XCTest, XCTestCase

### Community 59 - "Authentication"
Cohesion: 0.17
Nodes (11): DateTime?, DateTimeExtension, avatarUrl, createdAt, email, id, name, phone (+3 more)

### Community 60 - "Windows Platform"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 61 - "Configuration & Constants"
Cohesion: 0.17
Nodes (11): apiVersion, AppConfig, baseUrl, debugMode, dev, environment, fromFlavor, production (+3 more)

### Community 62 - "Logging System"
Cohesion: 0.17
Nodes (11): LoggerManager, d, e, i, _logger, loggerManager, loggerManagerProvider, logNotifierProvider (+3 more)

### Community 63 - "Dashboard Feature"
Cohesion: 0.22
Nodes (9): ../../../../core/errors/failures.dart, ../entities/dashboard.dart, DashboardRepositoryImpl, DashboardRepository, getDashboardData, call, GetDashboardUseCase, _repository (+1 more)

### Community 64 - "Network Layer"
Cohesion: 0.18
Nodes (10): dart:math, Duration, Interceptor, backoffFactor, initialDelay, maxRetries, onError, RetryInterceptor (+2 more)

### Community 65 - "Authentication"
Cohesion: 0.20
Nodes (7): Flutter, FlutterSceneDelegate, GeneratedPluginRegistrant, +registerWithRegistry, SceneDelegate, NSObject, UIKit

### Community 66 - "Profile Feature"
Cohesion: 0.22
Nodes (10): BulkMetaUpdate, fromJson, items, key, MetaItem, MetaUpdateRequest, SingleMetaUpdate, toJson (+2 more)

### Community 67 - "Theme & Styling"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 68 - "Configuration & Constants"
Cohesion: 0.20
Nodes (9): ../constants/app_constants.dart, DateFormatter, formatCurrency, formatDate, formatDateTime, formatNumber, formatRelative, formatTime (+1 more)

### Community 69 - "Dashboard Feature"
Cohesion: 0.22
Nodes (9): ../../../../core/errors/exceptions.dart, _cacheBox, cacheDashboardData, DashboardLocalDataSource, DashboardLocalDataSourceImpl, getCachedDashboardData, getLastSyncTime, setLastSyncTime (+1 more)

### Community 70 - "Storage & Preferences"
Cohesion: 0.20
Nodes (9): box, defaultValue, delete, exists, key, Pref, put, stream (+1 more)

### Community 71 - "Theme & Styling"
Cohesion: 0.20
Nodes (9): analyticsEnabled, autoSync, biometricEnabled, darkMode, fontSize, language, notificationsEnabled, props (+1 more)

### Community 72 - "Theme & Styling"
Cohesion: 0.22
Nodes (8): Color, build, child, isLoading, LoadingOverlay, LoadingWidget, message, size

### Community 73 - "Firebase & Push"
Cohesion: 0.33
Nodes (7): connectivity_plus, file_selector_macos, firebase_core, firebase_messaging, Foundation, geolocator_apple, sqflite_darwin

### Community 74 - "Dashboard Feature"
Cohesion: 0.22
Nodes (8): ../datasources/dashboard_local_datasource.dart, ../datasources/dashboard_remote_datasource.dart, ../../domain/repositories/dashboard_repository.dart, _getCachedDashboard, getDashboardData, localDataSource, networkInfo, remoteDataSource

### Community 75 - "Settings Feature"
Cohesion: 0.22
Nodes (8): ../datasources/settings_local_datasource.dart, ../../domain/entities/app_settings.dart, ../../domain/repositories/settings_repository.dart, SettingsLocalDataSource, SettingsLocalDataSourceImpl, getSettings, localDataSource, updateSettings

### Community 76 - "Theme & Styling"
Cohesion: 0.22
Nodes (8): double?, build, change, color, icon, StatCardWidget, title, value

### Community 77 - "Profile Feature"
Cohesion: 0.22
Nodes (8): ../dtos/index.dart, changePassword, getMetas, getProfile, updateMetas, updateProfile, uploadAvatar, package:cross_file/cross_file.dart

### Community 78 - "Dashboard Feature"
Cohesion: 0.22
Nodes (9): Equatable, ChartDataPointModel, StatCardModel, ChartDataPoint, StatCard, UserProfileModel, UserMeta, UserProfile (+1 more)

### Community 79 - "Profile Feature"
Cohesion: 0.22
Nodes (8): ../../features/profile/presentation/providers/profile_provider.dart, firebase_provider.dart, fcmSyncServiceProvider, service, FcmSyncService, return, ../services/fcm_sync_service.dart, ../storage/preferences/index.dart

### Community 80 - "Storage & Preferences"
Cohesion: 0.22
Nodes (8): box, boxName, clear, close, initBox, PrefGroup, UserPref, String get

### Community 81 - "Authentication"
Cohesion: 0.25
Nodes (8): AuthRemoteDataSource, AuthRemoteDataSourceImpl, _dioClient, getProfile, login, logout, register, ../models/user_model.dart

### Community 82 - "iOS Platform"
Cohesion: 0.25
Nodes (6): Any, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, AppDelegate, Bool, UIApplication

### Community 83 - "Group 83"
Cohesion: 0.25
Nodes (7): bool get, forceUnlock, isLocked, _locked, Mutex, waitUntilUnlocked, T

### Community 84 - "Network Layer"
Cohesion: 0.25
Nodes (7): dart:async, _expiredController, notifySessionExpired, onSessionExpired, SessionEvents, static final StreamController, static Stream

### Community 85 - "Authentication"
Cohesion: 0.25
Nodes (7): ../../domain/entities/user.dart, fromJson, fromLocalJson, toJson, toLocalJson, UserModel, User

### Community 86 - "Localization & i18n"
Cohesion: 0.39
Nodes (8): _AppState, build, routerProvider, currentLocaleProvider, localizationProvider, build, initState, settingsProvider

### Community 87 - "UI Widgets"
Cohesion: 0.32
Nodes (8): AvatarUploadWidget, _AvatarUploadWidgetState, FilePickerWidget, _FilePickerWidgetState, UniversalFilePickerWidget, _UniversalFilePickerWidgetState, State, StatefulWidget

### Community 88 - "UI Widgets"
Cohesion: 0.25
Nodes (7): build, getScreenSize, isDesktop, isMobile, isTablet, ResponsiveBuilder, ScreenSize

### Community 89 - "Authentication"
Cohesion: 0.25
Nodes (7): confirmPassword, email, name, password, RegisterRequestDto, toJson, username

### Community 90 - "Authentication"
Cohesion: 0.25
Nodes (7): clearLocalSession, getProfile, getToken, isLoggedIn, login, logout, register

### Community 91 - "Theme & Styling"
Cohesion: 0.29
Nodes (6): ./app_colors.dart, ./app_typography.dart, AppTheme, package:flutter/material.dart, package:flutter/services.dart, package:google_fonts/google_fonts.dart

### Community 92 - "Profile Feature"
Cohesion: 0.33
Nodes (5): ../../domain/entities/profile.dart, fromJson, fromLocalJson, toJson, toLocalJson

### Community 93 - "macOS Platform"
Cohesion: 0.47
Nodes (4): FlutterAppDelegate, AppDelegate, Bool, NSApplication

### Community 94 - "Authentication"
Cohesion: 0.33
Nodes (5): FlutterPluginRegistry, FlutterViewController, RegisterGeneratedPlugins(), MainFlutterWindow, NSWindow

### Community 95 - "iOS Platform"
Cohesion: 0.33
Nodes (5): handle_new_rx_page(), __lldb_init_module(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages., SBDebugger, SBFrame

### Community 96 - "Profile Feature"
Cohesion: 0.33
Nodes (5): id, key, props, value, package:equatable/equatable.dart

### Community 97 - "Localization & i18n"
Cohesion: 0.40
Nodes (6): AppLocalizations, _AppLocalizationsDelegate, AppLocalizationsEn, AppLocalizationsId, of, LocalizationsDelegate

### Community 98 - "Authentication"
Cohesion: 0.60
Nodes (3): GeneratedPluginRegistrant, FlutterEngine, Keep

### Community 99 - "Android Platform"
Cohesion: 0.60
Nodes (3): gradlew script, die(), warn()

### Community 100 - "Authentication"
Cohesion: 0.40
Nodes (4): auth_response_dto.dart, login_request_dto.dart, refresh_token_dto.dart, register_request_dto.dart

### Community 101 - "Storage & Preferences"
Cohesion: 0.40
Nodes (4): pref.dart, pref_group.dart, pref_providers.dart, user_pref.dart

### Community 102 - "Authentication"
Cohesion: 0.40
Nodes (4): LoginRequestDto, password, toJson, username

### Community 103 - "UI Widgets"
Cohesion: 0.50
Nodes (3): avatar_upload_widget.dart, file_picker_widget.dart, universal_file_picker_widget.dart

### Community 104 - "Authentication"
Cohesion: 0.50
Nodes (3): refreshToken, RefreshTokenDto, toJson

### Community 106 - "Architecture Concepts"
Cohesion: 0.67
Nodes (3): Conventional Commits, Semantic Versioning, Semantic Versioning

## Ambiguous Edges - Review These
- `Authentication Feature` → `Android Platform`  [AMBIGUOUS]
   · relation: unknown
- `Authentication Feature` → `iOS Platform`  [AMBIGUOUS]
   · relation: unknown
- `Authentication Feature` → `Linux Desktop Platform`  [AMBIGUOUS]
   · relation: unknown
- `Authentication Feature` → `macOS Platform`  [AMBIGUOUS]
   · relation: unknown
- `Authentication Feature` → `Web Platform`  [AMBIGUOUS]
   · relation: unknown
- `Authentication Feature` → `Windows Desktop Platform`  [AMBIGUOUS]
   · relation: unknown
- `Dashboard Feature` → `Android Platform`  [AMBIGUOUS]
   · relation: unknown
- `Dashboard Feature` → `iOS Platform`  [AMBIGUOUS]
   · relation: unknown
- `Dashboard Feature` → `Linux Desktop Platform`  [AMBIGUOUS]
   · relation: unknown
- `Dashboard Feature` → `macOS Platform`  [AMBIGUOUS]
   · relation: unknown
- `Dashboard Feature` → `Web Platform`  [AMBIGUOUS]
   · relation: unknown
- `Dashboard Feature` → `Windows Desktop Platform`  [AMBIGUOUS]
   · relation: unknown
- `Profile Feature` → `Android Platform`  [AMBIGUOUS]
   · relation: unknown
- `Profile Feature` → `iOS Platform`  [AMBIGUOUS]
   · relation: unknown
- `Profile Feature` → `Linux Desktop Platform`  [AMBIGUOUS]
   · relation: unknown
- `Profile Feature` → `macOS Platform`  [AMBIGUOUS]
   · relation: unknown
- `Profile Feature` → `Web Platform`  [AMBIGUOUS]
   · relation: unknown
- `Profile Feature` → `Windows Desktop Platform`  [AMBIGUOUS]
   · relation: unknown
- `Settings Feature` → `Android Platform`  [AMBIGUOUS]
   · relation: unknown
- `Settings Feature` → `iOS Platform`  [AMBIGUOUS]
   · relation: unknown
- `Settings Feature` → `Linux Desktop Platform`  [AMBIGUOUS]
   · relation: unknown
- `Settings Feature` → `macOS Platform`  [AMBIGUOUS]
   · relation: unknown
- `Settings Feature` → `Web Platform`  [AMBIGUOUS]
   · relation: unknown
- `Settings Feature` → `Windows Desktop Platform`  [AMBIGUOUS]
   · relation: unknown
- `Notifications Feature` → `Android Platform`  [AMBIGUOUS]
   · relation: unknown
- `Notifications Feature` → `iOS Platform`  [AMBIGUOUS]
   · relation: unknown
- `Notifications Feature` → `Linux Desktop Platform`  [AMBIGUOUS]
   · relation: unknown
- `Notifications Feature` → `macOS Platform`  [AMBIGUOUS]
   · relation: unknown
- `Notifications Feature` → `Web Platform`  [AMBIGUOUS]
   · relation: unknown
- `Notifications Feature` → `Windows Desktop Platform`  [AMBIGUOUS]
   · relation: unknown

## Knowledge Gaps
- **1087 isolated node(s):** `prepare-commit-msg.sh script`, `flutter_export_environment.sh script`, `+registerWithRegistry`, `createState`, `_rootNavigatorKey` (+1082 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **60 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Authentication Feature` and `Android Platform`?**
  _Edge tagged AMBIGUOUS (relation: related to) - confidence is low._
- **What is the exact relationship between `Authentication Feature` and `iOS Platform`?**
  _Edge tagged AMBIGUOUS (relation: related to) - confidence is low._
- **What is the exact relationship between `Authentication Feature` and `Linux Desktop Platform`?**
  _Edge tagged AMBIGUOUS (relation: related to) - confidence is low._
- **What is the exact relationship between `Authentication Feature` and `macOS Platform`?**
  _Edge tagged AMBIGUOUS (relation: related to) - confidence is low._
- **What is the exact relationship between `Authentication Feature` and `Web Platform`?**
  _Edge tagged AMBIGUOUS (relation: related to) - confidence is low._
- **What is the exact relationship between `Authentication Feature` and `Windows Desktop Platform`?**
  _Edge tagged AMBIGUOUS (relation: related to) - confidence is low._
- **What is the exact relationship between `Dashboard Feature` and `Android Platform`?**
  _Edge tagged AMBIGUOUS (relation: related to) - confidence is low._