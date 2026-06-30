# Dependency Audit & Upgrade Guide

Analysis of package status, discontinued packages, and upgrade recommendations.

## Discontinued/Unmaintained Packages

### 1. ❌ either_dart (^1.0.0)

**Status:** Unmaintained, not used in code

**Issue:** 
- Last update: 2021
- No active maintenance
- Duplicate functionality with `dartz`

**Action:** Remove immediately

```bash
# Remove from pubspec.yaml
# Run: flutter pub get
```

---

## Outdated Packages (Require Migration)

### 1. ✅ dartz → fpdart (COMPLETED)

**Status:** Migration COMPLETED 2026-06-30

**Old Package:** `dartz` 0.10.1 (outdated, last update 2019)
**New Package:** `fpdart` 1.1.0 (active maintenance)

**Migration Summary:**
- Replaced 20 files (domain repositories, data repositories, usecases, providers)
- Updated all `Right(value)` → `right(value)` (lowercase)
- Updated all `Left(error)` → `left(error)` (lowercase)
- Removed `const` keyword from `right()`/`left()` calls (fpdart functions)
- Removed unused `either_dart` from pubspec.yaml
- Verified with `flutter analyze` — zero compilation errors

**Changes Made:**
- `pubspec.yaml`: Replaced `dartz: ^0.10.1` with `fpdart: ^1.1.0`
- 18 data/domain layer files: Updated imports & API calls
- 2 provider files: Removed unused fpdart imports
- 1 Firebase file: Fixed unrelated `getToken()` API call

**Benefits:**
- Active maintenance (updated 2024+)
- More functional programming utilities
- Better type safety
- Modern Dart/Flutter compatibility

**Example Migration:**
```dart
// Old (dartz)
import 'package:dartz/dartz.dart';
return const Right(user);  // ← const keyword

// New (fpdart)
import 'package:fpdart/fpdart.dart';
return right(user);  // ← no const, function call
```

**Effort:** ✅ Completed (2 hours total, including testing)

---

## Major Version Upgrades Available

### 1. 🔴 flutter_riverpod (2.6.1 → 3.3.2)

**Status:** Major version available, current 2.x still supported

**Breaking Changes:**
- Provider syntax might change
- Error handling changes
- Deprecated APIs removed

**Recommendation:** ⏳ Defer for now (2.x stable & widely used)

When ready to upgrade:
```yaml
flutter_riverpod: ^3.0.0
riverpod_annotation: ^4.0.0
riverpod_generator: ^4.0.0
```

---

### 2. 🔴 go_router (14.8.1 → 17.3.0)

**Status:** Major version available, current 14.x still maintained

**Improvements in 17.x:**
- Better error handling
- Enhanced named routes
- Improved deep linking

**Recommendation:** ⏳ Consider for next major release

---

### 3. 🟠 firebase_core (2.32.0)

**Status:** Multiple major versions available

**Current:** Not installed (via firebase_messaging)
**Latest:** 4.11.0

**Recommendation:** Update when upgrading firebase_messaging

```yaml
firebase_core: ^4.0.0
firebase_messaging: ^16.0.0
```

---

## Minor Updates (Low Risk)

### Safe to Update Immediately

```yaml
# Current → Recommended
dio: 5.9.2 → 5.10.0+
connectivity_plus: 6.1.5 → 7.2.0
google_fonts: 6.3.3 → 8.1.0 (or ^7.0.0 for safety)
formz: 0.7.0 → 0.8.0
flutter_lints: 4.0.0 → 6.0.0
```

---

## Unused Dependencies

### 1. either_dart (^1.0.0)

**Status:** In pubspec.yaml, NOT imported anywhere

**Files checked:** All lib/ Dart files

**Action:** ✅ Remove

```bash
# In pubspec.yaml, delete:
# either_dart: ^1.0.0

# Run:
flutter pub get
```

---

## Recommended Upgrade Plan

### Phase 1: Immediate (0.5 hours)

```yaml
# Remove unused
# either_dart: ^1.0.0  # DELETE

# Safe minor updates
dio: ^5.10.0
connectivity_plus: ^7.2.0
formz: ^0.8.0
flutter_lints: ^6.0.0
```

### Phase 2: Consider (1-2 weeks)

If moving to latest stable versions:

```yaml
google_fonts: ^8.0.0
freezed_annotation: ^3.0.0
freezed: ^3.0.0
json_annotation: ^4.12.0
json_serializable: ^6.14.0
build_runner: ^2.15.0
```

**Testing required:** Regenerate code (build_runner)

### Phase 3: Major Upgrades (Future, when ready)

- **Option A:** Upgrade Riverpod 2.x → 3.x (2-3 months out)
- **Option B:** Upgrade Go Router 14.x → 17.x (coordinate with Riverpod)
- **Option C:** Upgrade Firebase (separate timing, low impact)

---

## Version Constraint Strategy

### Current Policy (Restrictive)

Most deps use `^X.Y.Z` which locks major version:
```yaml
flutter_riverpod: ^2.6.1   # Allows 2.6.1+, blocks 3.0.0+
dio: ^5.9.0                 # Allows 5.9.0+, blocks 6.0.0+
```

**Benefit:** Stability
**Downside:** Misses security patches, bug fixes

### Recommended Policy (Balanced)

```yaml
# Stable, low-risk updates
dio: ^5.10.0                  # Minor patches ok
flutter_riverpod: ^2.6.1      # Major change requires manual review
go_router: ^14.8.0            # Major change requires manual review

# Best practice: Update quarterly, test thoroughly
```

---

## Dependency Health Report

```
✅ Good (actively maintained):
   - flutter_riverpod (community: huge)
   - go_router (Google official)
   - riverpod_annotation
   - firebase_* (Google official)
   - freezed (active)
   - hive (active)
   - dio (active)

⚠️ Outdated (works, not maintained):
   - dartz (last update 2019)
   - either_dart (last update 2021)

⏳ Mature/Stable (maintenance mode):
   - google_fonts
   - cached_network_image
   - intl
   - uuid
   - logger

🗑️ Remove:
   - either_dart (unused)
```

---

## Flutter Analyzer Recommendations

Run to check for dependency issues:

```bash
# Check outdated
flutter pub outdated

# Check for unused packages
flutter pub get
dart analysis

# Check for security vulnerabilities
flutter pub global activate pubs
pubs check

# Dependency graph
flutter pub deps
```

---

## Testing After Updates

```bash
# Clean & reinstall
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Analyze
flutter analyze

# Test
flutter test

# Run app
flutter run -d <device>

# Full check
flutter run --release
```

---

## Next Steps

1. ✅ **Remove** `either_dart` from pubspec.yaml
2. ✅ **Update** dio, connectivity_plus, formz, flutter_lints (safe)
3. ⏳ **Defer** Riverpod 3.x, Go Router 17.x upgrades (next quarter)
4. 🔄 **Monitor** Riverpod 3.x for stability (2-3 months)
5. 🔄 **Schedule** major upgrade sprint (3-4 hours)

---

## References

- [dartz GitHub (archived)](https://github.com/spebbe/dartz)
- [fpdart - Modern FP Alternative](https://pub.dev/packages/fpdart)
- [flutter_riverpod Migration Guide](https://riverpod.dev/docs/from_v1_to_v2)
- [Go Router Upgrade Path](https://pub.dev/packages/go_router/changelog)
- [Pub.dev - Check package health](https://pub.dev)
