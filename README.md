# Adaptive Athlete (MVP)

Flutter training app with local Drift storage, optional Supabase authentication, cloud sync, AI-assisted planning, Apple Health and Garmin imports, and workbook export.

## Setup

1. Verify toolchain:
   - `flutter doctor`
2. Install deps:
   - `flutter pub get`
3. Generate Drift code:
   - `dart run build_runner build --delete-conflicting-outputs`
4. Run tests:
   - `flutter test`
5. Start app:
   - `flutter run`

## Supabase Config (No Secrets in Repo)

1. Copy `lib/config/supabase_config.example.dart` to `lib/config/supabase_config.dart`.
2. Fill:
   - `url = "<SUPABASE_URL>"`
   - `anonKey = "<SUPABASE_ANON_KEY>"`
3. `lib/config/supabase_config.dart` is gitignored.
4. In Supabase SQL Editor, run `supabase/schema.sql` to create the app tables.
5. Use `Settings -> Sync Now` to sync device and cloud changes. Conflicts are preserved for review in Settings.
6. Use `Daily -> Cardio` to log runs, bikes, or stair sessions, or import Garmin `Activities.csv` and Apple Health workouts. Running charts and pace calculations exclude other cardio.

For ongoing database development, follow `supabase/README.md`. The SQL Editor
bootstrap is retained for the existing MVP, but new schema changes should use
reviewed Supabase migrations after a remote baseline has been pulled.

## Android Emulator

1. Open Android Studio Device Manager.
2. Start an emulator image.
3. Run:
   - `flutter run -d emulator-5554`

## iOS Note

iOS deployment requires macOS and Xcode. Run `flutter devices`, then `flutter run -d <device-id>` for a connected iPhone or booted simulator.

## TestFlight Upload (CLI)

Use the included helper script to build and upload an iOS IPA to TestFlight via App Store Connect API key.

### One-time setup

1. Create a local env file:
   - `cp scripts/testflight.env.example scripts/testflight.env`
2. In App Store Connect, create or use an API key:
   - `Users and Access -> Integrations -> App Store Connect API`
3. Fill `scripts/testflight.env`:
   - `ASC_API_KEY_ID`
   - `ASC_API_ISSUER_ID`
   - `ASC_API_P8_PATH` (path to `AuthKey_<KEYID>.p8`)
4. Make the script executable (once):
   - `chmod +x scripts/testflight_upload.sh`

### Build + upload

- `scripts/testflight_upload.sh`
- The script auto-generates a timestamp-based iOS build number by default.
- To override it manually: `scripts/testflight_upload.sh --build-number 5`

### Upload existing IPA only

- `scripts/testflight_upload.sh --skip-build`
- Or specify a file: `scripts/testflight_upload.sh --ipa build/ios/ipa/adaptive_athlete.ipa`

### Validate only (no upload)

- `scripts/testflight_upload.sh --validate-only --skip-build`

## Security Note

No production secrets are committed. Keep all keys local and out of source control.
Do not store the Postgres database password in mobile app code.

## Version 1.1.0 reliability updates

- Sync stores the last acknowledged cloud copy on-device and uses an atomic,
  authenticated compare-and-set RPC. Concurrent edits remain available under
  Settings -> Review Sync Changes. Choosing a version does not bypass a newer
  cloud edit. Deletions use scoped tombstones to prevent stale-device resurrection.
- Ten-week plans and weekly performance sync alongside workouts. Profile switching
  requires a successful sync before clearing the previous profile's local cache.
- Units, equipment, movement restrictions, and local-only mode persist on the device.
- Settings shows the installed version/build, release notes, and last successful
  cloud-sync time. A local save is reported separately from cloud-sync completion.
- Planner response checks validate without replacing a plan. Failures preserve
  pasted/generated responses and show actionable recovery guidance. Unauthorized
  generation requests refresh the session and retry once.
- Apple Health imports and incremental sync use persisted cursors to avoid
  repeatedly processing older workouts. Ten-week plan date checks handle
  daylight-saving transitions, and weekly plan propagation validates dates.

On the first sync after upgrading, records that differ without a prior sync
baseline require a choice in Settings; neither copy is silently discarded.
