# Localization Setup

This project uses Flutter's internationalization (i18n) system with support for English (en) and Indonesian (id), with English as the default/fallback language.

## Structure

- **`lib/l10n/`** - Localization files
  - `app_en.arb` - English strings
  - `app_id.arb` - Indonesian strings
  - `app_localizations.dart` - Generated base class (do not edit)
  - `app_localizations_en.dart` - Generated English implementation
  - `app_localizations_id.dart` - Generated Indonesian implementation

- **`lib/core/localization/`** - Localization logic
  - `localization_provider.dart` - Riverpod provider for managing current locale

- **`l10n.yaml`** - Configuration for localization generation

## Usage

### In Widgets

Access localized strings using the `l10n` extension:

```dart
import 'package:flutter/material.dart';
import 'package:your_app/core/utils/extensions.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(context.l10n.appTitle);
  }
}
```

### Supported Keys

All localized strings are defined in the ARB files. Common keys include:

**Navigation:**
- `navigationHome`, `navigationDashboard`, `navigationProfile`, `navigationSettings`

**Authentication:**
- `authLogin`, `authRegister`, `authLogout`, `authEmail`, `authPassword`, `authForgotPassword`, etc.

**Settings:**
- `settingsTitle`, `settingsDarkMode`, `settingsLanguage`, etc.

**Common:**
- `commonOk`, `commonCancel`, `commonSave`, `commonDelete`, `commonLoading`, `commonError`, etc.

**Errors:**
- `errorNetwork`, `errorGeneral`, `errorNotFound`, `errorUnauthorized`, etc.

## Changing Language

Use the settings provider to change the language:

```dart
ref.read(settingsProvider.notifier).updateSetting(language: 'id');
```

Or use the localization provider directly:

```dart
ref.read(localizationProvider.notifier).setLocale('id');
```

## Adding New Strings

1. Add the string key-value pair to both `app_en.arb` and `app_id.arb`:

```json
{
  "myNewString": "English text here"
}
```

```json
{
  "myNewString": "Teks Indonesia di sini"
}
```

2. Run the code generation:

```bash
flutter gen-l10n
```

3. Use the new string in your widget:

```dart
Text(context.l10n.myNewString)
```

## Supported Locales

- English: `en`
- Indonesian: `id`

Default fallback: `en`

## Riverpod Integration

The localization system is fully integrated with Riverpod:

- `localizationProvider` - StateNotifier for managing the current locale
- `currentLocaleProvider` - Provider that returns the current Locale
- Settings changes automatically update the localization when language preference changes

## Configuration File

See `l10n.yaml` for generation configuration. Key settings:
- `arb-dir` - Directory containing ARB files
- `template-arb-file` - Base template (English)
- `output-localization-file` - Generated output filename
- `output-class` - Generated class name
