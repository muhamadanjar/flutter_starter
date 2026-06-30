# Package Upgrade Roadmap

Complete analysis of all packages and recommended upgrade strategy.

## Discontinued Packages ⚠️

### Transitive Dependencies (Auto-fixed by updating parent)

| Package | Status | Parent | Action |
|---------|--------|--------|--------|
| `build_resolvers` | ❌ Discontinued | build_runner | Update build_runner → 2.15.0+ |
| `build_runner_core` | ❌ Discontinued | build_runner | Update build_runner → 2.15.0+ |

**Action:** Update `build_runner` to 2.15.0+ (auto-resolves discontinued deps)

---

## Priority 1: Safe Minor Updates (This Week)

Low risk, no breaking changes expected. Update immediately.

```yaml
# Current → Recommended
dio: ^5.9.2 → ^5.10.0              # Patch: bug fixes
intl: ^0.20.2 → ^0.20.3            # Patch: bug fixes
cached_network_image: ^3.4.0 → ^3.4.1  # Patch: bug fixes
formz: ^0.7.0 → ^0.8.0             # Minor: feature additions
```

**Test:** `flutter analyze`, `flutter test`, run on device

---

## Priority 2: Medium Updates (Blocked - Requires 2A First)

**Status:** BLOCKED by hive_generator dependency incompatibility

**Issue:** hive_generator 2.0.1 requires old build tools:
- `build: ^2.0.0` (build_runner 2.15+ needs ^4.0.0)
- `source_gen: ^1.0.0` (json_serializable 6.14+ needs ^4.1.2)
- `analyzer: <7.0.0` (mockito 5.7+ needs ^13.0.0)

**Solution:** Update hive_generator first (Priority 2A)

### Priority 2A: hive_generator Update (Prerequisites for 2B)

```yaml
hive_generator: ^2.0.1 → ^2.1.0 (or latest compatible)
```

**Effort:** 1 hour
**Risk:** MEDIUM (code generation tool)
**Steps:**
1. Update hive_generator
2. Run `flutter pub run build_runner build --delete-conflicting-outputs`
3. Verify no generated code changes break functionality

### Priority 2B: Build Tools (After 2A)

Minor/patch updates to build tools. Requires code regeneration.

```yaml
# Current → Recommended
json_annotation: ^4.9.0 → ^4.12.0
json_serializable: ^6.8.0 → ^6.14.0
build_runner: ^2.4.9 → ^2.15.0    # Fixes discontinued packages
mockito: ^5.4.4 → ^5.7.0
```

**Steps:**
1. Update pubspec.yaml
2. Run `flutter pub get`
3. Run `flutter pub run build_runner build --delete-conflicting-outputs`
4. Run `flutter analyze` & `flutter test`

---

## Priority 3: Linter Updates (Next 2 Weeks)

Linter improvements, no functional impact.

```yaml
flutter_lints: ^4.0.0 → ^6.0.0
lints: ^4.0.0 → ^6.1.0
```

**Note:** May have lint warnings to fix (helpful improvements)

---

## Priority 4: Code Generation Framework (Next Month)

Code generation packages with breaking changes. Coordinate updates.

### Freezed (Annotation + Codegen)

```yaml
# Current → Recommended
freezed_annotation: ^2.4.4 → ^3.1.0
freezed: ^2.5.2 → ^3.2.5           # dev_dependencies
```

**Breaking Changes:** 
- May require minor code adjustments
- Check official migration guide

**Effort:** 1-2 hours (run build_runner, test)

**When:** After Priority 2 completed

---

## Priority 5: Major Version Upgrades (Next Quarter)

Breaking changes. Require significant testing. Do these separately.

### Option A: Riverpod 2.x → 3.x

**Current:** 2.6.1
**Latest:** 3.3.2
**Breaking:** Yes (provider API changes)

**Effort:** 4-6 hours
**Complexity:** HIGH
**Used:** Core state management (18 files)

```yaml
flutter_riverpod: ^3.0.0
riverpod_annotation: ^4.0.0
riverpod_generator: ^4.0.0
```

**Migration steps:**
1. Read [Riverpod v2→v3 Migration Guide](https://riverpod.dev/docs/from_v2_to_v3)
2. Update provider syntax
3. Test all features
4. Coordinate with team

**Timing:** After codebase stabilizes (2-3 weeks)

---

### Option B: Go Router 14.x → 17.x

**Current:** 14.8.1
**Latest:** 17.3.0
**Breaking:** Yes (route API changes)

**Effort:** 3-4 hours
**Complexity:** MEDIUM
**Used:** All navigation

```yaml
go_router: ^17.0.0
```

**Note:** Coordinate with Riverpod upgrade (may have related changes)

**Timing:** After Riverpod upgrade

---

### Option C: Firebase 2.x → 4.x

**Current:** 2.32.0 (firebase_core), 14.9.4 (firebase_messaging)
**Latest:** 4.11.0, 16.4.1

**Breaking:** Yes (initialization, API changes)

**Effort:** 2-3 hours
**Complexity:** MEDIUM
**Used:** Push notifications

```yaml
firebase_core: ^4.0.0
firebase_messaging: ^16.0.0
```

**Changes:**
- Firebase initialization may change
- Message handling API may update
- Platform-specific setup may differ

**When:** Can be done independently (after Priority 2)

---

### Option D: FL Chart 0.68 → 1.2

**Current:** 0.68.0
**Latest:** 1.2.0

**Breaking:** Unknown (check changelog)
**Effort:** 2-3 hours
**Complexity:** MEDIUM
**Used:** Dashboard charts

```yaml
fl_chart: ^1.2.0
```

**Before upgrading:**
1. Check [FL Chart Changelog](https://github.com/entrophy/fl_chart/releases)
2. Review breaking changes
3. Test charts on device

---

### Option E: Google Fonts 6.x → 8.x

**Current:** 6.3.3
**Latest:** 8.1.0

**Breaking:** Check changelog
**Effort:** 1-2 hours
**Complexity:** LOW
**Used:** Font loading

```yaml
google_fonts: ^8.0.0
# Or safer: ^7.0.0 (between current and latest)
```

---

## Packages NOT Needing Updates

| Package | Version | Reason |
|---------|---------|--------|
| `flutter_riverpod` (2.6.1) | ✅ Current | Stable, actively used; defer 3.x |
| `go_router` (14.8.1) | ✅ Current | Stable, widely used; defer 17.x |
| `hive` | ✅ Latest | Stable, well-maintained |
| `uuid` | ✅ Latest | Stable, no new versions |
| `logger` | ✅ Latest | Stable, no new versions |
| `equatable` | ✅ Latest | Stable, no new versions |
| `shimmer` | ✅ Latest | Stable, no new versions |
| `flutter_svg` | ✅ Latest | Stable, no new versions |
| `iconsax` | ✅ Latest | Stable, no new versions |
| `cached_network_image` | ✅ Latest (3.4.1) | Nearly latest |
| `animations` | ✅ Latest | Stable, no new versions |
| `flutter_native_splash` | ✅ Latest | Stable, no new versions |
| `fpdart` | ✅ Latest (1.1.0) | Newly migrated |

---

## Upgrade Timeline

### Week 1 (NOW)
- [ ] Priority 1: Safe minor updates (dio, intl, formz, cached_network_image)
- [ ] Test on device

### Week 2
- [ ] Priority 2: Build tools (json_annotation, build_runner, mockito)
- [ ] Run `flutter pub run build_runner build`
- [ ] Full test suite

### Week 3
- [ ] Priority 3: Linter updates (flutter_lints, lints)
- [ ] Fix any lint warnings

### Week 4
- [ ] Priority 4: Freezed (3.x)
- [ ] Test code generation

### Month 2
- [ ] Priority 5A: Riverpod 3.x (separate sprint)
- [ ] Coordinate with team

### Month 2-3
- [ ] Priority 5B: Go Router 17.x (after Riverpod)
- [ ] Priority 5C: Firebase 4.x (independent)
- [ ] Priority 5D/E: Chart/font libraries

---

## Safety Checklist

Before each upgrade:

```bash
# 1. Backup current state
git status
git commit -m "Pre-upgrade checkpoint"

# 2. Update single package/group
# Edit pubspec.yaml

# 3. Verify compatibility
flutter pub get
flutter analyze

# 4. Regenerate code (if needed)
flutter pub run build_runner build --delete-conflicting-outputs

# 5. Test locally
flutter test
flutter run -d <device>

# 6. Verify on multiple platforms
flutter run -d android
flutter run -d ios
# flutter run -d chrome (web)
```

---

## Risk Assessment

| Package | Risk | Effort | Impact |
|---------|------|--------|--------|
| dio, intl, formz | LOW | 0.5h | None |
| json_*, build_runner | LOW | 1h | Code generation |
| flutter_lints | LOW | 0.5h | Lint warnings only |
| freezed 3.x | MEDIUM | 2h | Code generation |
| Riverpod 3.x | HIGH | 6h | Core state mgmt |
| Go Router 17.x | HIGH | 4h | All routing |
| Firebase 4.x | MEDIUM | 3h | Push notifications |
| FL Chart 1.x | MEDIUM | 3h | Dashboard |
| Google Fonts 8.x | LOW | 1h | Font loading |

---

## Alternative Packages to Consider

### State Management (Instead of Riverpod 3.x)
- `provider` (simple, stable)
- `getx` (feature-rich but opinionated)
- `bloc` (event-driven, testable)

**Recommendation:** Stick with Riverpod (already invested, best in class)

### Navigation (Instead of Go Router 17.x)
- `auto_route` (code generation)
- `routemaster` (declarative)

**Recommendation:** Stick with Go Router (official, well-maintained)

### Charts (Instead of FL Chart)
- `syncfusion_flutter_charts` (powerful, paid)
- `charts` (Google maintained, stable)
- `candlesticks` (simple, lightweight)

**Recommendation:** FL Chart 1.x is solid, safe to upgrade

---

## Notes

- **Transitive dependencies:** Automatically updated when parent updates
- **Lock file:** Contains exact versions; may differ from pubspec.yaml constraints
- **Breaking changes:** Always read changelogs before major version upgrades
- **Testing:** More critical after major updates
- **Coordination:** Inform team before major state management/routing changes

---

## Summary

**Immediate Action:** Priority 1 updates (1 week)
**Short Term:** Priority 2-3 updates (2 weeks)
**Medium Term:** Freezed 3.x, Firebase 4.x (1 month)
**Long Term:** Riverpod 3.x, Go Router 17.x (2-3 months, separate initiatives)
