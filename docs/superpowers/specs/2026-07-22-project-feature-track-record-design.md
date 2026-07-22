# Project-gated Feature Record & Track Record — Design

Date: 2026-07-22

## Context

Tile server (`TILE_SERVER_URL`, `/api/v1/openapi.json`) shipped a new **projects**
API that replaces the old stubbed upload path used by Track Record
(`docs/TRACK_RECORD_GUIDE.md`). Both Track Record (GPS line capture) and a new
Feature Record (point/polygon capture with a dynamic form) must now go through
a **Project** the user selects first — a project defines `geometry_type`
(`point` / `line` / `polygon`) and a dynamic `form_schema` used to render the
attribute form. All records sync to the server as generic Features under that
project.

### Confirmed API shape (live `GET /api/v1/projects` sample)

```json
{
  "id": "bb483f93-976f-4765-82cb-b041ff3d3d1f",
  "name": "Area",
  "description": "",
  "geometry_type": "polygon",
  "form_schema": [
    {"name": "name", "label": "Nama", "type": "text", "required": true},
    {"name": "description", "label": "Deskripsi", "type": "textarea", "required": false},
    {"name": "year", "label": "Tahun", "type": "number", "required": false, "min": 2000, "max": 2030},
    {"name": "select", "label": "Select", "type": "select", "required": false, "options": ["adfdf", "dfdf"]}
  ],
  "layer_id": null,
  "is_published": false,
  "feature_count": 1,
  "created_at": "2026-07-21T15:57:03.855354Z",
  "updated_at": "2026-07-21T16:09:09.901631Z"
}
```

Line-type project ("Jalan") has fields `name` (text) and `fule` (type `file`,
`extensions: ["jpg"]`) — confirms attribute forms apply to line/track projects
too, not just point/polygon.

### Endpoints used

| Purpose | Endpoint |
|---|---|
| List projects | `GET /api/v1/projects` |
| Get one project (schema) | `GET /api/v1/projects/{project_id}` |
| Create feature (record) | `POST /api/v1/projects/{project_id}/features` — body `{geometry, attributes, created_by}` |
| Upload attachment (file field) | `POST /api/v1/projects/{project_id}/attachments` — multipart `file` + `field_name`, returns `{id, project_id, filename, url, content_type, size_bytes}` |

`FeatureCreate.geometry` / `FeatureUpdate.geometry` are untyped objects — app
sends standard GeoJSON geometry (`Point` / `LineString` / `Polygon`).

Attachment response has no `feature_id` link (server limitation as of this
spec). Workaround: upload the file **before** building the feature's
`attributes`, and store the returned `url` string as the value of that
field's key (`attributes[field_name] = url`). If the feature create/sync
later fails and is retried, the already-uploaded file is *not* re-uploaded
(url is already cached in local attributes).

## Scope

In scope:
- New `features/project` module: list + fetch projects, in-memory selection.
- Project-picker gate before Track Record start and before Feature Record capture.
- Track Record: add `projectId` + `attributes` (dynamic form filled on Stop), replace stubbed `_upload()` with real `POST .../features` (geometry = `LineString`).
- New Feature Record capture (point via GPS, polygon via map vertex-tap), offline-first Hive + outbox, same sync target.
- Shared `DynamicFormSheet` rendering `text`, `textarea`, `number` (min/max), `select`, `file` (upload-then-embed-url).

Out of scope (explicitly deferred):
- Creating/editing projects in-app (admin/web owns this).
- Any UI for `layer_id`, `is_published`, `publish`/`unpublish`, `export`, `.geojson` endpoints.
- Editing/deleting already-synced remote features from the app.
- Multi-file / multiple attachments per field.
- Persisting `selectedProjectProvider` across app restarts (session-only for v1).

## Architecture

```mermaid
flowchart TD
    subgraph project feature (new)
      PR[ProjectRepository] -->|GET /projects| API1[(Tile Server)]
      PP[ProjectPickerSheet] --> PR
      SEL[selectedProjectProvider]
    end

    subgraph map feature (existing, extended)
      TFAB[TrackRecordFab] --> SEL
      FFAB[FeatureRecordFab - new]  --> SEL
      TFAB --> TREPO[TrackRecordRepository]
      FFAB --> FREPO[FeatureRecordRepository - new]
      TREPO -->|Hive: record_tracks| HIVE1[(Hive)]
      FREPO -->|Hive: record_features| HIVE2[(Hive)]
      TREPO -->|sync: POST .../features geometry=LineString| API1
      FREPO -->|sync: POST .../features geometry=Point/Polygon| API1
      DYNFORM[DynamicFormSheet] --> TREPO
      DYNFORM --> FREPO
      DYNFORM -->|file field: POST .../attachments| API1
    end
```

### `features/project` (new, clean architecture)

| Layer | File | Role |
|---|---|---|
| Domain entity | `domain/entities/project.dart` | `Project`, `ProjectFormField` (name, label, type, required, min, max, options, extensions) |
| Domain repository | `domain/repositories/project_repository.dart` | `getProjects()`, `getProject(id)` → `Either<Failure, T>` |
| Domain usecase | `domain/usecases/get_projects_usecase.dart` | thin callable |
| Data model | `data/models/project_model.dart` | `fromJson`, defensive parsing (unknown field `type` kept as raw string) |
| Data datasource | `data/datasources/project_remote_datasource.dart` | `ExternalDioClient` calls |
| Data repository | `data/repositories/project_repository_impl.dart` | `Either` + typed exception mapping (mirrors `map_repository_impl.dart`) |
| Presentation | `presentation/providers/project_providers.dart` | `projectsProvider` (FutureProvider, refreshable), `selectedProjectProvider` (StateProvider<Project?>, in-memory) |
| Presentation | `presentation/widgets/project_picker_sheet.dart` | bottom sheet, filters list by allowed `geometryType`s passed in |

### Track Record changes

- `TrackRecord` entity: add `projectId` (String, required after start), `attributes` (Map<String,dynamic>, default `{}`).
- `TrackRecordModel`: extend `fromJson`/`toJson` for the two new fields (Hive JSON-string storage, additive — old records without these fields parse with `projectId: ''`/`attributes: {}` defaults for backward compat within local storage only, no server migration needed since nothing has synced yet).
- `TrackRecordFab`:
  - On tap-to-start: if `selectedProjectProvider` is null or not `geometry_type == 'line'`, open `ProjectPickerSheet(allowed: ['line'])` first.
  - On stop: open `DynamicFormSheet(project.formSchema)`, merge result into `attributes`, then `saveTrack(...)` (re-queues `pending`).
- `TrackRecordRepositoryImpl._upload()`: replace stub with real call — build `geometry: {"type": "LineString", "coordinates": points.map((p) => [p.longitude, p.latitude]).toList()}`, `attributes`, POST to `/projects/{projectId}/features`, map response/errors through existing `Either<Failure, T>` pattern.

### Feature Record (new)

Mirrors Track Record's file layout exactly, under `features/map/{domain,data}/*record*`:

| Layer | File |
|---|---|
| Domain entity | `domain/entities/feature_record.dart` — `FeatureRecord{id, projectId, geometryType, geometry (raw List of [lng,lat] or single [lng,lat]), attributes, syncStatus, createdAt, syncedAt}` |
| Domain repository | `domain/repositories/feature_record_repository.dart` — `getRecords()`, `saveRecord(FeatureRecord)`, `deleteRecord(id)`, `getPending()`, `syncPending()` |
| Domain usecases | `save_feature_record_usecase.dart`, `sync_feature_records_usecase.dart` |
| Data model | `data/models/feature_record_model.dart` |
| Data datasource | `data/datasources/feature_record_local_datasource.dart` — Hive box `record_features`, same one-JSON-string-per-box pattern as track records |
| Data repository | `data/repositories/feature_record_repository_impl.dart` — same outbox shape as `TrackRecordRepositoryImpl`, POST geometry `Point`/`Polygon` |

Capture UX:
- `FeatureRecordFab` (new widget, placed next to `TrackRecordFab`): tap → if no selected project with `geometry_type in [point, polygon]`, open `ProjectPickerSheet(allowed: ['point','polygon'])`.
  - If picked project is `point`: immediately grab one GPS fix (`GpsService.getCurrentLocation()`), go straight to `DynamicFormSheet`.
  - If picked project is `polygon`: map enters "vertex tap" mode (crosshair cursor, tap adds vertex, min 3 required, floating "Done"/"Cancel" bar) → `DynamicFormSheet` → save.
- Both paths end in `FeatureRecord(syncStatus: pending)` saved to Hive immediately (offline-first), then the existing sync trigger path (connectivity listener / app resume, already used by track record's `syncPending`) also flushes feature records.

### `DynamicFormSheet` (shared, new widget in `features/map/presentation/widgets/`)

- Input: `List<ProjectFormField>`, optional initial `Map<String,dynamic>`.
- Renders per `field.type`:
  - `text` → `TextFormField`
  - `textarea` → `TextFormField(maxLines: null)`
  - `number` → `TextFormField(keyboardType: number)`, validators from `min`/`max`
  - `select` → `DropdownButtonFormField<String>(items: field.options)`
  - `file` → image-pick button → on pick, immediately `POST /projects/{projectId}/attachments` (multipart, `field_name: field.name`) → on success store `url` as the field's value and show a thumbnail/filename chip; on failure show inline error and block that field (Save stays disabled while a file field is mid-upload or errored)
  - unknown `type` → rendered as read-only text field with a "unsupported field" note (defensive, same philosophy as `layer_type` handling in the map feature)
- `required: true` fields block Save via form validation until filled.
- Returns `Map<String,dynamic>` attributes on submit, or `null` on cancel (caller keeps existing/prior attributes, does not save).

## Error handling

- Project list fetch fails → snackbar with retry action in `ProjectPickerSheet`; picker stays open.
- No projects of the required `geometry_type` exist → picker shows empty state ("No {type} projects available — create one first").
- Attachment upload fails → inline field error, does not block *other* fields, blocks Save specifically because that field's value would be incomplete (unless field not `required`, in which case Save is allowed with the field left empty and a "skipped" note — matches existing `required` semantics).
- Feature/track sync failure → existing `failed` `SyncStatus` + retry-on-next-`syncPending()` (unchanged behavior, just now hitting a real endpoint instead of the stub).

## Testing

- `project_repository_impl_test.dart` — JSON mapping against the three sample projects above (text/textarea/number/select/file field types, all three `geometry_type`s).
- `dynamic_form_sheet_test.dart` (widget test) — one case per field type: renders correct input widget, required-field validation blocks submit, `select` options populate, `number` min/max validation.
- `track_record_repository_impl_test.dart` — extend existing tests: sync now builds `LineString` geometry + `attributes`, mock Dio POST and assert payload shape.
- `feature_record_repository_impl_test.dart` (new) — mirrors track record repo tests: local CRUD, outbox `syncPending`, `Point` and `Polygon` geometry payload construction.
- Manual/live: reuse the `localhost:8050` live integration test pattern already used for `MapRemoteDataSource` (`memory: tile-server-api-quirks`) to hit the real `/projects` and `/projects/{id}/features` endpoints once during development.

## Open questions carried as deferred (not blocking)

- Attachment↔feature linkage is server-side ambiguous (no `feature_id` on `AttachmentResponse`); current design treats the returned `url` as sufficient and doesn't attempt further linking. Revisit if server adds explicit linkage.
- `layer_id`/`is_published`/publish flow intentionally unused — projects are assumed pre-published or publish status irrelevant to record capture.
