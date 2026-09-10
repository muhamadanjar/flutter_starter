# Google Social Login

## Overview

Google authentication is handled by User Management API. The Flutter app never
receives a Google client secret or a Google access token. It opens the API's
Google provider flow, verifies PKCE on return, and stores only the resulting
internal application session.

## Flow

1. Flutter creates a PKCE verifier, challenge, and state.
2. It opens `GET /auth/social/google/login` with the registered OAuth
   `client_id`, `redirect_uri`, PKCE challenge, and state.
3. User Management API completes Google OAuth and creates or links the local
   user.
4. The API redirects to the allowed app callback with a one-time code.
5. Flutter exchanges the code at `/oauth/token`, then exchanges that OAuth
   access token at `/auth/oauth-exchange` for the normal app session.

## Configuration

Set the following public values in `.env` (copied from `.env.example`):

```dotenv
SOCIAL_OAUTH_CLIENT_ID=your-first-party-oauth-client-id
SOCIAL_NATIVE_REDIRECT_URI=enterprise-flutter-app://auth/callback
SOCIAL_WEB_REDIRECT_URI=https://app.example.com/auth.html
```

The User Management API OAuth client must be first-party and allow each exact
redirect URI. The API also requires `OAUTH_GOOGLE_CLIENT_ID` and
`OAUTH_GOOGLE_CLIENT_SECRET`; those values remain server-side.

Android and iOS register `enterprise-flutter-app` as their callback scheme.
Web uses `web/auth.html`, which returns the popup callback through
`postMessage`.

## Troubleshooting

- `Invalid redirect_uri`: add the exact URI (including path) to the API OAuth
  client's allowlist.
- `Provider 'google' tidak tersedia`: set the API's Google credentials.
- State or PKCE error: ensure the callback returns to the same app instance;
  do not manually copy a callback URL between devices.
