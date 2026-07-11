# 0001 — Home hub replaces the Dashboard feature

Date: 2026-07-11
Status: Accepted

## Context

The app shipped with a full clean-architecture `dashboard` feature (entity, model,
repository, remote/local datasources, usecase, provider, chart widgets) built around
e-commerce KPIs: total revenue, orders, revenue chart, recent activities. The backend
is the User Management API (localhost:8070), which we do not control, and it has no
`/dashboard` endpoint — the feature could never receive real data. The bottom nav
also carried an "Analytics" placeholder tab that pointed at the same fake dashboard.

## Decision

Replace the dashboard with a presentation-only `home` feature:

- `lib/features/home/` contains only a presentation layer. It composes data that
  already lives in other features: the authenticated user from the auth provider
  (greeting header) and the notification list provider (unread count + 3 recent
  items), plus quick-action shortcuts to Profile, Settings, and Change Password.
- No domain or data layer: Home owns no domain concept and calls no endpoint of
  its own, so repository/usecase scaffolding would be ceremony without value.
- The entire `lib/features/dashboard/` tree was deleted, along with
  `ApiConstants.dashboard`, `AppConstants.dashboardCacheKey`, the dashboard l10n
  keys, the `fl_chart` dependency, and the Analytics nav tab.
- Route renamed `/dashboard` → `/home` (initial location and auth redirect target).

## Alternatives considered

- **Server-driven generic dashboard** (backend returns widget descriptors, app
  renders them): rejected — requires a new backend endpoint and we do not control
  the backend.
- **Keep clean-arch skeleton for home** (domain layer aggregating other repos):
  rejected — duplicate fetching and indirection with no domain concept behind it.

## Consequences

- Home shows only real data; no fake KPIs.
- If a real dashboard/analytics API ever appears, it should be built as a new
  feature with its own domain layer, not by extending Home.
