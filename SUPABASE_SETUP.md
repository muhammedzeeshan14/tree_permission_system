# TPMS Multi-Device Setup — Stage 1 (Supabase + Offline-First)

Local sqflite is still the offline cache. Supabase Postgres will be the
shared source of truth. Stage 1 does NOT change any workflow; it only
adds the foundation so Stage 2 can sync table by table.

## 1. Create Supabase project

1. https://supabase.com/dashboard > New project.
2. SQL Editor > paste `supabase/schema.sql` > Run.
3. Storage > create private buckets: `tpms-documents`, `tpms-photos`.
4. Project Settings > API > copy Project URL + anon key.

## 2. Run app with Supabase enabled

```powershell
flutter pub get
flutter run `
  --dart-define=SUPABASE_URL=https://xyzcompany.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

Without those flags the app runs in local-only mode (current behavior).

Desktop / Android / iOS all use the same flags. For persistent
per-device config, add them to your IDE run configuration.

## 3. What Stage 1 added

- `supabase_flutter`, `connectivity_plus` dependencies.
- `lib/config/supabase_config.dart` — dart-define config.
- `lib/services/supabase_service.dart` — safe init, no-op when unconfigured.
- `lib/services/connectivity_service.dart` — online/offline stream.
- `lib/services/sync_service.dart` — durable `sync_queue`, `pendingCount()`,
  `lastSync()`, `syncNow()` skeleton. Stage 2 drains the queue.
- DB v40: `sync_queue` table + `updatedAt` on applications/trees/users
  (+ `authId` on users for later Auth linking).
- `main.dart` inits connectivity + Supabase before `runApp`.

## 4. Next stages (tell me stage by stage)

- Stage 2 DONE: DB v41 (`updatedAt` on all synced tables, `users.email`),
  real push/pull in `SyncService.syncNow()`, `users.auth_id` linking via
  synthetic `<username>@tpms.local` emails, auto-sync on reconnect,
  `SyncButton` widget (`lib/widgets/sync_button.dart` — add to any AppBar
  via `actions: [const SyncButton()]`). repos hooked: applications, trees.
  Limitation: integer PKs can collide if two devices create the same id;
  keep creation on one device until UUID migration (Stage 3).
- Stage 3 (pending): Supabase Auth email login UI, conflict UI, role-based
  RLS policies, Storage upload for photos/documents, UUID PKs.
- Code + template edits you mentioned: tell me the screen/file and the
  exact change and I will apply it on top of this foundation.

### Stage 2 Supabase checklist

1. Re-run `supabase/schema.sql` (adds `users.email`; safe with
   `IF NOT EXISTS` — or `ALTER TABLE public.users ADD COLUMN email text`).
2. Supabase Dashboard > Authentication > Sign In / Sign Ups: enable Email.
   First online login per username auto-creates
   `<username>@tpms.local` with the local password and stores `auth_id`.
3. Test: on device A create/edit an application or tree, tap SyncButton,
   note "Pushed N". On device B tap SyncButton, note "Pulled M".
