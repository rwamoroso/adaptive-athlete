# Adaptive Athlete (MVP)

Flutter app scaffold with local Drift database, optional Supabase auth bootstrap, basic training UI, CSV export, and mocked AI analysis with audit logs.

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
5. Use `Settings -> Sync Now` to push local Drift data into Supabase.
6. Use `Daily -> Run Inputs` to add manual run data or import Garmin `Activities.csv`.

## Android Emulator

1. Open Android Studio Device Manager.
2. Start an emulator image.
3. Run:
   - `flutter run -d emulator-5554`

## iOS Note

iOS deployment requires macOS + Xcode. This Windows environment can still build/run Android, web, desktop targets as supported by your Flutter setup.

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
