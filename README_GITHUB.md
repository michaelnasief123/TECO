
# TECO_Clock_V001

This repository is a GitHub-ready Flutter project for **TECO Clock_V001** (UDP sender app).

## Quick build with Codemagic (recommended)
1. Push this repo to GitHub (or create a repo and upload).
2. Sign in to https://codemagic.io and connect your GitHub repo.
3. Create a workflow for Flutter and select **Build APK**.
4. Run the build and download the generated APK.

## Local build
```bash
flutter pub get
flutter run
flutter build apk --release
```

## Notes
- The app sends UDP ASCII packets to configured IP/port (default 192.168.4.1:2000).
- Packet format: YYYYMMDDWWHHMMSSAPBB (see source for details).
- Settings are persisted with SharedPreferences.
