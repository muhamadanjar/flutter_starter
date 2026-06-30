# Priority 1 Updates — Safe Immediate Upgrades

Low-risk updates that can be applied immediately. No breaking changes expected.

## Quick Overview

| Package | Current | Latest | Type | Risk |
|---------|---------|--------|------|------|
| `dio` | 5.9.2 | 5.10.0 | Patch | 🟢 LOW |
| `intl` | 0.20.2 | 0.20.3 | Patch | 🟢 LOW |
| `cached_network_image` | 3.4.0 | 3.4.1 | Patch | 🟢 LOW |
| `formz` | 0.7.0 | 0.8.0 | Minor | 🟢 LOW |

**Total Impact:** Bug fixes, minor features, performance improvements
**Estimated Time:** 15 minutes
**Breaking Changes:** NONE

---

## Step-by-Step Update

### 1. Update pubspec.yaml

Replace these lines:

```yaml
# Old
dio: ^5.4.3+1
intl: ^0.20.2
cached_network_image: ^3.3.1
formz: ^0.7.0

# New
dio: ^5.10.0
intl: ^0.20.3
cached_network_image: ^3.4.1
formz: ^0.8.0
```

### 2. Install Updates

```bash
flutter pub get
```

Expected output:
```
Changed X dependencies!
```

### 3. Verify No Issues

```bash
flutter analyze
```

Should show only existing info/lint warnings (no new errors)

### 4. Quick Test

```bash
# Run on device
flutter run -d <device_name>

# Or use Chrome for quick web test
flutter run -d chrome
```

### 5. Commit

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: update dependencies (dio, intl, cached_network_image, formz)"
```

---

## What Each Update Fixes

### dio 5.9.2 → 5.10.0 (Patch)

**Changelog highlights:**
- Bug fixes in request/response handling
- Improved error handling
- Minor performance optimizations

**Impact on app:** 
- More reliable API calls
- Better timeout handling
- Potential fix for edge-case network errors

**Files affected:** 
- `lib/core/network/dio_client.dart`
- Any features using Dio (auth, dashboard, profile, settings)

**Test:** Login, load dashboard, make API calls

---

### intl 0.20.2 → 0.20.3 (Patch)

**Changes:** Maintenance release, bug fixes

**Impact on app:**
- Better date/time formatting (if any issues existed)
- Locale handling improvements

**Files affected:**
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` (uses DateFormatter)
- Localization system

**Test:** Check date displays in dashboard, settings

---

### cached_network_image 3.4.0 → 3.4.1 (Patch)

**Changes:** Bug fixes in image caching

**Impact on app:**
- More reliable image caching
- Better memory management
- Fixes edge-case cache invalidation issues

**Files affected:**
- Dashboard images
- Profile pictures
- Any `CachedNetworkImage` usage

**Test:** Scroll dashboard, verify images load & cache correctly

---

### formz 0.7.0 → 0.8.0 (Minor)

**Changes:** New validation utilities, minor API additions

**Impact on app:**
- Better form validation
- More form field types
- Improved error messages (if using new features)

**Note:** Existing form code continues to work unchanged

**Files affected:**
- `lib/features/auth/presentation/pages/` (login/register forms)
- Any pages with `CustomTextField`

**Test:** Try login, registration, form validation

---

## Rollback Plan (If Needed)

```bash
# If something breaks:
git checkout pubspec.yaml pubspec.lock
flutter pub get
flutter run
```

---

## After Update

Monitor for any issues:
- ✅ No new compiler errors
- ✅ No new runtime crashes
- ✅ API calls work (network requests)
- ✅ Images load correctly
- ✅ Forms validate properly
- ✅ Dates display correctly

---

## Estimated Testing Time

| Feature | Time |
|---------|------|
| Build & analyze | 2-3 min |
| Test on device | 5-10 min |
| Spot-check features | 5 min |
| **Total** | **~15 min** |

---

## Notes

- All updates are compatible with current Flutter/Dart versions
- No code changes needed
- Safe to update immediately
- No coordination needed with team

---

## Next Steps

After this update succeeds:
1. ✅ This PR merges
2. ⏳ Wait 1 week for stability feedback
3. ⏳ Then apply Priority 2 updates (build tools)
4. ⏳ Then Priority 3 (linters)
5. ⏳ Then Priority 4 (freezed 3.x)

See [PACKAGE_UPGRADE_ROADMAP.md](PACKAGE_UPGRADE_ROADMAP.md) for full strategy.
