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

## Security Note

No production secrets are committed. Keep all keys local and out of source control.
Do not store the Postgres database password in mobile app code.
