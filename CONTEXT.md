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
User-initiated Session teardown. Calls GET /logout to invalidate token on server (failure is non-blocking), blanks fcm_token User Meta on server, then clears local storage (tokens, user data). Router redirects to login.
_Avoid_: session expiry (that's automatic on token failure)

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
Keeping the `fcm_token` User Meta current: posted on app startup (if logged in), after login, and on FCM token rotation; skipped when unchanged from the locally cached value; blanked on Logout (POST /auth/metas with empty value). Failures are silent and non-blocking.

### Implementation Notes

**Token Refresh Mutex**:
DioClient uses a mutex to serialize concurrent token refresh calls. When multiple requests hit 401 simultaneously, only the first one calls POST /auth/refresh; others wait for the result and reuse the new token. Refresh call bypasses all interceptors (bare Dio, no Bearer header to avoid expired-token loop) and must include Authorization header (server requires it via get_current_user dependency). Response shape: `{data: {auth: {access_token, refresh_token?, ...}}}`.

**Firebase Initialization Resilience**:
FirebaseService is a singleton that degrades gracefully when Firebase.initializeApp() fails (e.g., missing google-services.json). Methods return null/empty-stream/no-op instead of throwing. App continues to run; FCM features silently become unavailable. Detected via `_isInitialized` flag.

**Auth-FCM Lifecycle**:
After successful login/register or on app startup (checkAuthStatus), AuthNotifier calls _onAuthenticated() which triggers FcmSyncService.sync() + startTokenRefreshListener(). Token syncs happen on: app startup, after login, and whenever Firebase rotates token (onTokenRefresh stream). Listener remains active for session duration.
