# Semantic Versioning Guide

Automatic semantic versioning for pushes to master branch.

## Version Format

Follow [Semantic Versioning 2.0.0](https://semver.org/):

```
MAJOR.MINOR.PATCH+BUILD

Example: 1.5.3+42
         │ │ │  └─ Build number
         │ │ └──── Patch (bug fixes)
         │ └─────── Minor (new features)
         └───────── Major (breaking changes)
```

## Version Rules

**MAJOR** (1.0.0 → 2.0.0)
- Breaking API changes
- Major feature rewrites
- Riverpod 2.x → 3.x upgrade
- Go Router 14.x → 17.x upgrade

**MINOR** (1.2.3 → 1.3.0)
- New features
- New screens/flows
- New API endpoints
- Package upgrades (non-breaking)

**PATCH** (1.2.3 → 1.2.4)
- Bug fixes
- Performance improvements
- Documentation updates
- Dependency patches (dio, intl, etc.)

**BUILD** (1.2.3+5 → 1.2.3+6)
- CI/CD builds
- Test builds
- Internal iterations

## Current Version

**File:** `pubspec.yaml`

```yaml
version: 1.0.0+1
```

Current: **1.0.0** (first production release)

## Commit Message Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description

[optional body]
[optional footer]
```

### Commit Types

| Type | Version | Example |
|------|---------|---------|
| `fix:` | PATCH | `fix: resolve network timeout in dio client` |
| `feat:` | MINOR | `feat: add push notifications support` |
| `feat!:` | MAJOR | `feat!: refactor auth system with breaking changes` |
| `docs:` | PATCH | `docs: update setup guide` |
| `style:` | PATCH | `style: format code per dart guidelines` |
| `refactor:` | PATCH | `refactor: extract common widget logic` |
| `perf:` | PATCH | `perf: optimize dashboard rendering` |
| `test:` | PATCH | `test: add unit tests for auth provider` |
| `chore:` | PATCH | `chore: update dependencies` |

### Examples

**Bug Fix (PATCH)**
```
fix(auth): resolve token expiry not triggering refresh

Token expiry check was using < instead of <=.
This caused expired tokens to not trigger refresh.

Fixes #123
```

**New Feature (MINOR)**
```
feat(notifications): add firebase push notification support

- Implemented FirebaseService for FCM initialization
- Created notification providers for Riverpod
- Added notification settings widget
- Supports foreground, background, and tap handlers

Resolves #456
```

**Breaking Change (MAJOR)**
```
feat!: migrate dartz to fpdart for functional programming

BREAKING CHANGE: Either API changed from Right/Left to right/left (lowercase functions).
Update all repository implementations to use new API.

Migration steps:
- Replace Right(value) with right(value)
- Replace Left(error) with left(error)
- Remove const keyword from right/left calls

See docs/DEPENDENCY_AUDIT.md for details.
```

## Automatic Versioning (CI/CD)

### GitHub Actions Workflow

Create `.github/workflows/semantic-version.yml`:

```yaml
name: Semantic Versioning

on:
  push:
    branches:
      - master

jobs:
  version:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 'latest'

      - name: Bump version and push tag
        uses: PaulHatch/semantic-version-action@v5.1.0
        with:
          major_pattern: "feat!:"
          minor_pattern: "feat:"
          patch_pattern: "fix:"
          change_path: "pubspec.yaml"
          bump_each_commit: false
          namespace: v
          tag_prefix: "v"

      - name: Update pubspec.yaml
        run: |
          VERSION=${{ steps.version.outputs.version }}
          BUILD=${{ github.run_number }}
          sed -i "s/version: .*/version: $VERSION+$BUILD/" pubspec.yaml

      - name: Commit version bump
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add pubspec.yaml
          git commit -m "chore: bump version to ${{ steps.version.outputs.version }}+${{ github.run_number }}"
          git push

      - name: Create GitHub Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: v${{ steps.version.outputs.version }}
          release_name: v${{ steps.version.outputs.version }}
          body: |
            See CHANGELOG.md for details.
          draft: false
          prerelease: false
```

### Local Versioning (Manual)

If CI/CD not available, update manually:

```bash
# Check current version
grep "^version:" pubspec.yaml

# Update version in pubspec.yaml
# 1.0.0+1 → 1.1.0+1 (minor release)

# Commit
git add pubspec.yaml
git commit -m "chore: bump version to 1.1.0"

# Tag
git tag -a v1.1.0 -m "Release version 1.1.0"

# Push
git push origin master
git push origin v1.1.0
```

## Changelog

### File: `CHANGELOG.md`

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- New features being developed

### Changed
- Changes to existing features

### Fixed
- Bug fixes in development

## [1.2.0] - 2026-07-15

### Added
- Firebase push notifications support (#456)
- Adaptive layouts for tablet/desktop (#123)
- Semantic versioning automation

### Changed
- Migrated from dartz to fpdart for functional programming
- Updated Riverpod to 2.6.1

### Fixed
- Token refresh not triggering on expiry (#789)
- Offline banner width on desktop

### Security
- Updated Firebase to 2.32.0 for security patches

## [1.1.0] - 2026-07-01

### Added
- Environment configuration with flavors (dev/staging/prod)
- Multi-platform builds (Android, iOS, Web)

### Changed
- Refactored DIO client to use AppConfig

### Fixed
- Base URL hardcoding in network layer

## [1.0.0] - 2026-06-30

### Added
- Initial release
- Clean Architecture implementation
- Riverpod state management
- Go Router navigation
- Firebase integration
- Hive offline storage
```

### Updating Changelog

On each release:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- Feature 1
- Feature 2

### Changed
- Change 1
- Change 2

### Fixed
- Bug fix 1
- Bug fix 2

### Security
- Security patch 1
```

## Version Bumping Examples

### Example 1: Bug Fix (PATCH)

```bash
# Commit message
fix: resolve null exception in dashboard loading

# Current: 1.0.0+1
# New:     1.0.1+2
```

**Update pubspec.yaml:**
```yaml
version: 1.0.1+2
```

### Example 2: New Feature (MINOR)

```bash
# Commit message
feat: add firebase push notifications

# Current: 1.0.0+1
# New:     1.1.0+1
```

**Update pubspec.yaml:**
```yaml
version: 1.1.0+1
```

### Example 3: Breaking Change (MAJOR)

```bash
# Commit message
feat!: migrate to fpdart, drop dartz support

BREAKING CHANGE: API changes from Right/Left to right/left

# Current: 1.0.0+1
# New:     2.0.0+1
```

**Update pubspec.yaml:**
```yaml
version: 2.0.0+1
```

## Build Increment

Build number increments on each CI/CD run:

```
Build 1:  1.0.0+1
Build 2:  1.0.0+2
Build 3:  1.0.0+3

Release:  1.0.0+42 (42nd build pushed to master)
```

## Viewing Version Info

### In App

```dart
// lib/core/config/app_version.dart
class AppVersion {
  static const String version = '1.0.0';
  static const String build = '1';
  static const String fullVersion = '$version+$build'; // 1.0.0+1
}

// Use in code
debugPrint('App version: ${AppVersion.fullVersion}');
```

### Command Line

```bash
# Check pubspec.yaml
grep "^version:" pubspec.yaml

# Output
# version: 1.0.0+1
```

### In Release Notes

```bash
# View release info
git describe --tags

# Output
# v1.0.0

# Show commits since last release
git log v1.0.0..HEAD --oneline
```

## Release Checklist

Before releasing:

- [ ] All tests passing (`flutter test`)
- [ ] Code analysis clean (`flutter analyze`)
- [ ] Commit messages follow convention
- [ ] CHANGELOG.md updated
- [ ] pubspec.yaml version updated
- [ ] Git tag created (v1.0.0)
- [ ] GitHub release created
- [ ] APK/IPA/Web built for release
- [ ] Release notes published

## Git Tag Format

```bash
# List tags
git tag

# Output
v1.0.0
v1.1.0
v2.0.0

# View tag details
git show v1.1.0

# Delete tag (if needed)
git tag -d v1.1.0
git push origin :refs/tags/v1.1.0
```

## Pre-release Versions

For beta/rc releases:

```
1.0.0-alpha.1      # Alpha
1.0.0-beta.1       # Beta
1.0.0-rc.1         # Release Candidate
1.0.0               # Final Release
```

**pubspec.yaml:**
```yaml
version: 1.0.0-rc.1+1
```

## Tools

### Automated (CI/CD)
- GitHub Actions (semantic-version-action)
- GitLab CI (commitizen)

### Manual
- `commitizen`: Interactive commit messages
- `semantic-release`: Automated releases
- `changelog-cli`: Generate changelogs

Install commitizen:
```bash
# Global
npm install -g commitizen

# Use
cz commit
```

## References

- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Flutter Versioning](https://flutter.dev/docs/release/release-notes)

## Troubleshooting

### Version not bumping

- Check commit message format (must follow Conventional Commits)
- Verify CI/CD workflow running
- Check GitHub Actions logs

### Tag already exists

```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin :refs/tags/v1.0.0

# Create new tag
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0
```

### Need to revert version

```bash
# Reset to previous tag
git reset --soft v1.0.0

# Update pubspec.yaml
# Then commit with new message
git commit -m "fix: revert to previous version"
```

## Summary

| Step | Action |
|------|--------|
| **1. Commit** | Use conventional commits (fix:, feat:, feat!:) |
| **2. Push** | Push to master branch |
| **3. Automate** | CI/CD automatically bumps version |
| **4. Tag** | Git tag created (v1.0.0) |
| **5. Release** | GitHub release published |
| **6. Build** | APK/IPA/Web built for release |

**Current Version:** See `pubspec.yaml`
**Release History:** See `CHANGELOG.md`
**All Releases:** See GitHub Releases page
