# Colastica XI

Fantasy cricket app built with Flutter, Riverpod, Supabase, and external cricket data feeds.

## What Is Production-Ready Here

- Email/password auth is wired to Supabase.
- Protected routes redirect unauthenticated users to login.
- Matches, squads, teams, contests, and leaderboards are provider-driven instead of hardcoded in screens.
- Team creation is validated for player count, credits, role mix, and per-team limits.
- Secrets are no longer stored in app source and must be injected at build time.
- The app fails with a clear configuration screen if required deployment values are missing.

## Required Build-Time Configuration

This app uses `--dart-define` or `--dart-define-from-file`.

Copy [dart-defines.example.json](/C:/FlutterProjects/dart-defines.example.json) to your own local file such as `dart-defines.local.json`, fill in your real values, and keep that file out of source control.

Required:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `CRICAPI_API_KEY`

Optional:

- `CRICAPI_BASE_URL`
- `PREMIUM_FEED_BASE_URL`
- `PREMIUM_FEED_API_KEY`

## Run Locally

```bash
flutter pub get
flutter run --dart-define-from-file=dart-defines.local.json
```

## Release Builds

Android:

```bash
flutter build apk --release --dart-define-from-file=dart-defines.local.json
```

Web:

```bash
flutter build web --release --dart-define-from-file=dart-defines.local.json
```

iOS:

```bash
flutter build ios --release --dart-define-from-file=dart-defines.local.json
```

## Supabase Tables

### `teams`

```sql
create table if not exists teams (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  match_id text not null,
  team_name text not null,
  players jsonb not null,
  captain_id text not null,
  vice_captain_id text not null,
  total_credits int not null,
  created_at timestamp with time zone default now()
);
```

### `contests`

```sql
create table if not exists contests (
  id uuid primary key default gen_random_uuid(),
  match_id text not null,
  contest_name text not null,
  max_teams int not null,
  entry_fee int default 0,
  prize_description text not null,
  created_at timestamp with time zone default now()
);
```

### `contest_entries`

```sql
create table if not exists contest_entries (
  id uuid primary key default gen_random_uuid(),
  contest_id uuid references contests(id) not null,
  team_id uuid references teams(id) not null,
  user_id uuid references auth.users not null,
  created_at timestamp with time zone default now(),
  unique (contest_id, team_id)
);
```

### `leaderboard`

```sql
create table if not exists leaderboard (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  match_id text not null,
  team_id uuid references teams(id) not null,
  username text,
  captain_name text,
  total_points int default 0,
  rank int default 0,
  updated_at timestamp with time zone default now()
);
```

## Important Deployment Note

Premium sports feeds should not be called directly from an exposed mobile or web client with raw provider secrets. If you use a premium feed, put it behind your own secure backend or proxy and pass that proxy URL into:

- `PREMIUM_FEED_BASE_URL`
- `PREMIUM_FEED_API_KEY`

If you do not provide that premium feed config, the app falls back to CricAPI for match and squad data.

## Verification

Recommended checks before release:

```bash
flutter analyze
flutter test
flutter build apk --release --dart-define-from-file=dart-defines.local.json
```
