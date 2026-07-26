# 0002 — Handling tile server chunk-upload API quirks

Date: 2026-07-26
Status: Accepted

## Context

Implementing chunked file upload (LayerUpload, see CONTEXT.md) against the tile
server's `/api/v1/uploads/*` endpoints, verified live against
`https://tileserver.jattirayyakonsultindo.co.id/api/v1/openapi.json` plus direct
curl calls (spec alone was insufficient — two behaviors are either undocumented
or buggy):

1. **Chunk body format is undocumented.** `POST /uploads/{upload_id}/{chunk_index}`
   has no `requestBody` in the OpenAPI schema at all. Live testing confirmed the
   server expects the raw chunk bytes as the request body with
   `Content-Type: application/octet-stream` — not `multipart/form-data`, which is
   what every other upload endpoint on this server (`POST /upload`) and this
   codebase's existing upload code (`profile` avatar upload) use.

2. **`/cancel` always returns HTTP 500, even when it succeeds.** Calling
   `POST /uploads/{upload_id}/cancel` returns `500 Internal Server Error` in every
   case tested — on an upload with zero chunks sent, and on one with all chunks
   already sent. In both cases, a subsequent `GET /uploads/{upload_id}/status`
   confirms the status did change to `cancelled`. The 500 is a response-serialization
   bug on the server, not an indication the cancel failed.

   Separately (not the same bug, but adjacent): resending a chunk index that was
   already received also returns 500, with no observed state corruption — treated
   as a genuine error, not retried.

3. **`POST /uploads/{upload_id}/tile` (raster finalize) is currently broken.**
   Tested three ways against the live server — an empty/dummy file, a valid
   4×4 no-data GeoTIFF (`gdal_create`), and a valid 64×64 RGB GeoTIFF with real
   burned pixel values (`gdal_create -burn`) — every call returned
   `500 Internal Server Error` with a generic `text/plain` body, and
   `GET /status` afterward still showed `uploaded` with `error_message: null`
   (the failure never even reaches the `failed` status). This looks like a
   server-side bug independent of input validity, not something fixable from
   the client. By contrast `POST /uploads/{upload_id}/save` (vector finalize)
   was tested end-to-end successfully: it returns `200` synchronously with
   `{"status":"done", "tile_url_template":..., ...}`, confirming **`done`** —
   not `ready` — is the real terminal-success status string (this also matches
   the existing `MapLayer.isReady => status == 'done'` check in
   `lib/features/map/domain/entities/map_layer.dart`). `processing` and
   `failed` remain unconfirmed strings, since no test run reached either.

## Decision

- Send chunks as raw bytes (`Content-Type: application/octet-stream`), not
  multipart. Do not follow the `/upload` (non-chunked) endpoint's multipart
  pattern for this code path.
- Treat any HTTP 500 from `/cancel` as a possible success, not a definite
  failure: after calling cancel, immediately call `GET /status` and trust that
  result. Only surface an error to the user if status does not confirm
  `cancelled`.
- Do not resend a chunk index that a prior successful response (or the status
  endpoint's `chunk_map`) already confirmed as received — treat that 500 as a
  real failure, since resend-of-completed is a client bug, not a server quirk
  to swallow.
- Use `done` as the `LayerUpload` terminal-success status, not `ready`.
- Implement the raster (`/tile`) code path fully per the documented contract
  anyway, rather than dropping it from scope — the request/response shapes are
  correct even though the live endpoint currently 500s. Mark it as
  known-broken/untestable-live in the plan and in code comments at the call
  site, so a future fix on the server side "just works" without an app change.

## Alternatives considered

- **Report `/cancel` 500 as an error to the user, unconditionally**: rejected —
  it would make working cancels look broken every single time, since the bug
  is 100% reproducible, not intermittent.
- **Ask the tile-server team to fix `/cancel` before building on it**: not
  pursued for this iteration — the app-side workaround (verify via status) is
  small, reversible, and unblocks the feature now; revisit if the server side
  is ever fixed (see Consequences).

## Consequences

- Any code path calling `/cancel` must always follow up with a status check —
  a bare "did the HTTP call succeed" check would produce false failures 100%
  of the time.
- If the tile server later fixes `/cancel` to return 200 on success, the
  status-check-after-cancel logic still works (it doesn't assume 500), so no
  follow-up change is required — but the "treat 500 as maybe-success" branch
  becomes dead code worth removing then.
- Chunk send code must not be copy-pasted from the existing multipart avatar/
  profile upload code — the two upload styles are genuinely different wire
  formats on this backend.
- Raster (GeoTIFF) uploads cannot be verified end-to-end on-device right now —
  manual QA for the raster path is blocked until the tile server team fixes or
  explains the `/tile` 500. Vector (`.geojson`/shapefile) uploads can be fully
  verified today.
- The `processing` and `failed` status strings used in the `LayerUpload` status
  enum are best-effort guesses (chosen to read naturally, matching the shape
  of `error_message`/progress fields), not confirmed against a live response.
  Whoever eventually gets `/tile` working (or forces a real failure) must
  verify these two strings and fix the enum mapping if they differ.
