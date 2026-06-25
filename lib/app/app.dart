import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/localization_provider.dart';
import '../features/settings/presentation/providers/settings_provider.dart';
import '../l10n/app_localizations.dart';
import 'app/router/app_router.dart';
import 'core/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settingsState = ref.watch(settingsProvider);
    final isDarkMode = settingsState.settings?.darkMode ?? true;
    final locale = ref.watch(currentLocaleProvider);

    // Update localization when settings change
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.settings?.language != next.settings?.language && next.settings?.language != null) {
        ref.read(localizationProvider.notifier).setLocaleFromLanguageCode(next.settings?.language);
      }
    });

    return MaterialApp.router(
      title: 'Enterprise App',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(context),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
