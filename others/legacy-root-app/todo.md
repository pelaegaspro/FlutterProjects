# Colastica XI Flutter App - TODO

## Core Architecture & Setup
- [x] Project initialization with Expo SDK 54
- [x] Theme system (colors, typography)
- [x] Constants and configuration
- [x] Router setup with GoRouter (Riverpod-based)

## Data Models
- [x] Match model
- [x] Player model
- [x] Team model
- [x] Contest model
- [x] Leaderboard model
- [x] User model

## Services & APIs
- [x] Supabase service (auth, database)
- [x] Sportradar API service
- [x] CricAPI fallback service
- [x] Smart API service (with fallback logic)

## State Management (Riverpod Providers)
- [x] Auth provider (login, signup, session)
- [x] Match provider (fetch matches, filter by status)
- [x] Team provider (create, fetch, update teams)
- [x] Leaderboard provider (realtime updates)
- [x] Player provider (fetch players for selection)

## UI Widgets & Components
- [x] Match card widget
- [x] Player card widget
- [x] Shimmer loading widget
- [x] Bottom navigation bar
- [x] Status badge (LIVE, UPCOMING, COMPLETED)
- [x] Captain/VC badge indicators

## Screens
- [x] Splash screen (2.5s fade animation)
- [x] Login/Signup screen
- [x] Matches screen (Live | Upcoming | Completed tabs)
- [x] Player selection screen (with validation)
- [x] Captain & Vice Captain selection screen
- [x] My Teams screen
- [x] Contests screen
- [x] Leaderboard screen (realtime)
- [x] Profile screen

## Features & Functionality
- [x] Email/password authentication
- [x] Session persistence
- [x] Pull-to-refresh on matches
- [x] Player selection validation (11 players, 100 credits, team limits)
- [x] Team creation and submission to Supabase
- [x] Contest joining
- [x] Leaderboard realtime subscription
- [x] API fallback logic (Sportradar → CricAPI)
- [x] Offline state handling
- [x] Error handling and snackbars

## Assets & Branding
- [ ] App icon generation (to be done with user's branding)
- [ ] Splash screen background
- [ ] Android adaptive icon
- [ ] App name and slug in config

## Configuration
- [x] .env file with API keys (via webdev_request_secrets)
- [x] Supabase tables creation (teams, leaderboard, contests)
- [x] pubspec.yaml with all dependencies

## Testing & Delivery
- [x] Verify all screens render correctly
- [x] Test end-to-end user flows
- [x] Check API integration
- [ ] Final checkpoint and delivery
