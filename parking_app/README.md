# parking_app

Create a new Flutter project parking app.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

```bash
flutter --version
```

## Navigate to your Flutter project directory

```bash
cd parking_app
```

## Get dependencies

```bash
flutter pub get
```

## Run the app (this will build and launch on connected device/emulator)

```bash
flutter run
```

## For Android

```bash
flutter build apk --release
```

## For iOS

```bash
flutter build ios --release
```

## iOS Simulator

> Note: `xcrun` is a command-line tool in macOS that runs or locates development tools within the Xcode developer directory.
> `simctl` is a subcommand of xcrun for controlling the iOS Simulator programmatically.

```bash
# List all available iOS simulators
xcrun simctl list devices

# Launch a specific iOS simulator
open -a Simulator

# Or launch a specific device
xcrun simctl boot "iPhone 15 Pro" # Replace with your simulator name

# Run Flutter app in the launched simulator
flutter run
```

## Android Emulator

```bash
# List available Android emulators
flutter emulators

# Launch a specific Android emulator
flutter emulators --launch <emulator_id>

# Alternative way to launch using Android tools
cd ~/Library/Android/sdk/emulator
./emulator -avd <emulator_name>

# Run Flutter app in the launched emulator
flutter run
```

## Other

```bash
flutter gen-l10n
flutter pub run build_runner build --delete-conflicting-outputs
flutter clean
flutter pub get
cd ios
pod install --repo-update
flutter run -d ios
flutter run -d android
```

## DART

```dart
// final l10n = AppLocalizations.of(context);
// Text(l10n.login);
```
