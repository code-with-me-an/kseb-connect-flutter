# KSEB Connect

KSEB Connect is a complaint registration, tracking and management Flutter app for KSEB (Kerala State Electricity Board). The app allows administrators and users to register complaints, track their status, and manage complaint workflows. It also includes a community complaint feature where users can view complaints submitted by others and upvote complaints they also face.

## Key Features

- Complaint registration and tracking for KSEB services.
- Admin dashboard for managing and updating complaint statuses.
- Community complaints: view all user-submitted complaints and upvote the same complaint if affected.
- User profile and complaint history.
- Push notifications and real-time updates (if configured).

## Project Structure

This repository is a Flutter project. Main app code is under `lib/` and Android-specific files under `android/`.

## Requirements

- Flutter SDK (stable)
- Android SDK and platform-tools (ADB)
- A connected Android device or emulator

## Useful Commands

Run these commands from the project root.

### Flutter: common development commands

```bash
# Fetch dependencies
flutter pub get

# Run the app on the default device or an attached device (choose device with `flutter devices`)
flutter run

# Run on a specific device by id
flutter run -d <deviceId>

# Build an Android APK (debug/release)
flutter build apk --debug
flutter build apk --release

# Build an Android App Bundle for Play Store
flutter build appbundle --release

# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Format Dart code
flutter format .

# Clean build artifacts
flutter clean

# List available emulators and launch one
flutter emulators
flutter emulators --launch <emulatorId>

# List connected devices
flutter devices
```

### ADB: connect and device management (Android)

Use these to connect devices over USB or TCP/IP. On Windows, ensure device drivers are installed and USB debugging is enabled in Developer Options.

```bash
# List devices (USB and TCP)
adb devices

# If using USB and connection doesn't show, restart server
adb kill-server
adb start-server

# For wireless debugging: enable TCP/IP on the device (via USB first)
adb usb
adb tcpip 5555
# Then connect to device IP
adb connect <device-ip>:5555

# Example: adb connect 192.168.1.10:5555

# Show logs
adb logcat

# Forward a device port to host (if needed)
adb reverse tcp:8081 tcp:8081

# Disconnect wireless
adb disconnect <device-ip>:5555
```

Notes:
- Replace `<deviceId>` and `<device-ip>` with actual values. Use `flutter devices` or `adb devices` to list IDs and IPs.
- For wireless: connect device via USB first to enable `adb tcpip` or use the device's Wireless Debugging feature (Android 11+).

## Running the app on an Android device (example)

1. Ensure dependencies are installed: `flutter pub get`.
2. Start an emulator or connect a device (`flutter devices` to verify).
3. Run:

```bash
flutter run -d <deviceId>
```

### Git: common repository commands

Use these commands for typical workflows: creating branches, pushing, merging, resolving conflicts, and undoing changes.

```bash
# Create and switch to a new branch
git checkout -b feature/<name>

# Stage and commit changes
git add .
git commit -m "Short, clear message"

# Push branch to remote and set upstream
git push -u origin feature/<name>

# Update local main and rebase or merge into your branch
git fetch origin
git checkout main
git pull origin main
git checkout feature/<name>
git rebase origin/main   # or `git merge origin/main`

# Merge a feature branch into main (locally)
git checkout main
git merge --no-ff feature/<name>
git push origin main

# Resolve merge conflicts: edit files, then
git add <file>
git commit

# Undo changes (working tree)
git restore <file>            # discard changes in working dir
git restore --staged <file>   # unstage

# Undo last commit but keep changes staged
git reset --soft HEAD~1

# Undo last commit and discard changes
git reset --hard HEAD~1

# Revert a pushed commit (creates a new commit)
git revert <commit-hash>

# Recover lost commits (use reflog)
git reflog
git checkout -b recover/<name> <commit-hash>

# Re-apply a commit (cherry-pick)
git cherry-pick <commit-hash>
```

## Contribution & Next Steps

- Implement tests and CI for builds.
- Add README sections for environment setup, screenshots, and deployment when available.


