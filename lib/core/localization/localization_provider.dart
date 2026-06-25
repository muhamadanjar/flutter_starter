import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class LocalizationState {
  final Locale locale;

  const LocalizationState({required this.locale});

  LocalizationState copyWith({Locale? locale}) {
    return LocalizationState(locale: locale ?? this.locale);
  }
}

class LocalizationNotifier extends StateNotifier<LocalizationState> {
  static const defaultLocale = Locale('en');
  static const supportedLocales = [Locale('en'), Locale('id')];

  LocalizationNotifier() : super(const LocalizationState(locale: defaultLocale));

  void setLocale(String languageCode) {
    final locale = Locale(languageCode);
    if (supportedLocales.contains(locale)) {
      state = state.copyWith(locale: locale);
    }
  }

  void setLocaleFromLanguageCode(String? languageCode) {
    if (languageCode != null) {
      setLocale(languageCode);
    }
  }

  Locale getLocaleForLanguage(String? language) {
    if (language == null) return defaultLocale;
    final locale = Locale(language);
    return supportedLocales.contains(locale) ? locale : defaultLocale;
  }
}

final localizationProvider = StateNotifierProvider<LocalizationNotifier, LocalizationState>((ref) {
  return LocalizationNotifier();
});

final currentLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(localizationProvider).locale;
});
