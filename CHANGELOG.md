# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Comprehensive documentation suite
- Semantic versioning automation
- Environment configuration with flavors (dev/staging/prod)
- Firebase push notifications support
- Adaptive responsive layouts (mobile/tablet/desktop)

### Changed
- Migrated from dartz to fpdart for functional programming
- Refactored dio client to use AppConfig for base URL

### Fixed
- Token refresh not triggering on expiry
- Base URL hardcoding in network layer
- Offline banner width on desktop
- MissingPluginException on Flutter Web (Firebase)
- ThemeData colorSchemeSeed conflict

### Security
- Updated Firebase to 2.32.0 for security patches
- Removed unused either_dart dependency

## [1.0.0] - 2026-06-30

### Added
- Initial release
- Clean Architecture implementation (domain/data/presentation layers)
- Riverpod 2.5.1 state management & dependency injection
- Go Router 14.8.0 declarative routing
- Dio 5.10.0 HTTP client with interceptors
- Hive 2.2.3 offline storage with Riverpod integration
- Firebase Cloud Messaging push notifications
- Material Design 3 with dual light/dark themes
- Responsive Framework adaptive layouts
- Internationalization (i10n) support via intl
- Code generation (Freezed, json_serializable)
- Functional programming utilities (fpdart)
- Comprehensive documentation
- Multi-environment support (dev/staging/production)
- Adaptive navigation (mobile bottom nav, tablet/desktop sidebar)

### Features
- **State Management:** Riverpod with code generation
- **Navigation:** Go Router with deep linking
- **Network:** Dio with auth interceptors, retry logic
- **Storage:** Hive for offline-first data
- **UI:** Material 3, responsive, dark/light themes
- **Push Notifications:** Firebase Cloud Messaging
- **Architecture:** Clean Architecture pattern
- **Error Handling:** Either pattern (fpdart)
- **Code Generation:** Freezed models, routes, providers

### Documentation
- AGENTS.md: Project rules & stack
- CLEAN_ARCHITECTURE.md: Architecture patterns & examples
- ADAPTIVE_LAYOUTS.md: Responsive UI patterns
- ENVIRONMENT_SETUP.md: Flavor configuration (dev/staging/prod)
- ENVIRONMENT_CONFIGURATION.md: Alternative approaches
- FIREBASE_SETUP.md: Push notifications setup
- FIREBASE_QUICK_START.md: Quick reference
- DEPENDENCY_AUDIT.md: Package audit & migrations
- PACKAGE_UPGRADE_ROADMAP.md: Upgrade strategy
- SETUP_GUIDE.md: First-time setup for developers
- SEMANTIC_VERSIONING.md: Versioning & release process

### Dependencies
```yaml
# Core
flutter_riverpod: ^2.5.1
go_router: ^14.8.0
riverpod_annotation: ^2.3.5

# Network & Storage
dio: ^5.10.0
connectivity_plus: ^6.0.3
hive: ^2.2.3
hive_flutter: ^1.1.0

# UI & Responsive
responsive_framework: ^1.4.0
google_fonts: ^6.2.1
cached_network_image: ^3.4.0

# Code Generation & Utility
freezed_annotation: ^2.4.1
json_annotation: ^4.9.0
fpdart: ^1.1.0
uuid: ^4.4.0
intl: ^0.20.2

# Firebase
firebase_core: ^2.28.0
firebase_messaging: ^14.8.0
```

### Git Operations
- Allowed: git log, status, diff, show, add, commit, push
- Forbidden: reset --hard, push --force, rebase -i, checkout .

---

## How to Update Changelog

When making commits to master:

1. **Use Conventional Commits:**
   ```
   fix: bug description
   feat: feature description
   feat!: breaking change
   ```

2. **Version bumps automatically** based on commit type
3. **Update CHANGELOG.md** under `[Unreleased]` section
4. **On release**, version becomes `[X.Y.Z] - YYYY-MM-DD`

See [SEMANTIC_VERSIONING.md](docs/SEMANTIC_VERSIONING.md) for complete guide.
