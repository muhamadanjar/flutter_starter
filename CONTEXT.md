# Enterprise Flutter App

Mobile client for the User Management API (localhost:8070 in dev). Clean-architecture Flutter app with feature modules (auth, profile, dashboard, notifications, settings).

## Language

### Session & Tokens

**Session**:
The authenticated state held on-device: access token, refresh token, and cached user. Created by Login, destroyed by Logout or Session Expiry.

**Access Token**:
Short-lived bearer token attached to every API request. Renewed transparently via Token Refresh.
_Avoid_: token (ambiguous), auth token

**Token Refresh**:
Exchanging the stored refresh token at POST /auth/refresh for a new access token. Triggered automatically on a 401, serialized by a mutex, performed on a bare HTTP client (no interceptors).

**Session Expiry**:
Token Refresh itself failing (refresh token invalid/expired). Resolves by clearing the Session and redirecting to login.
_Avoid_: logout (that's user-initiated)

**Logout**:
User-initiated Session teardown. Client-side only (server has no logout endpoint); blanks the device's fcm_token User Meta first, then clears local storage.

### Profile & Metas

**Profile**:
The user's editable identity fields: first_name, last_name, email, phone. Updated via PUT /auth/profile. Fields outside this set are not part of Profile.
_Avoid_: name (single field — the API models first/last separately)

**Avatar**:
User's profile image, replaced via multipart POST /auth/update-avatar (field name `file`). The authoritative avatar URL comes from re-fetching /auth/info, not from the upload response.

**User Meta**:
A server-side key/value pair scoped to the authenticated user, upserted via POST /auth/metas (single item or list). Keys in use: `fcm_token`, location keys.
_Avoid_: metadata, settings (device-local settings live in Hive)

**FCM Token Sync**:
Keeping the `fcm_token` User Meta current: posted on app startup (if logged in), after login, and on FCM token rotation; skipped when unchanged from the locally cached value; blanked on Logout. Failures are silent and non-blocking.
