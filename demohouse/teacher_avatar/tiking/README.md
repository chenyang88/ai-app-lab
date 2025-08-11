# tiking

A Flutter project supporting iOS and Android platforms only.

## Supported Platforms

This project has been configured to support **iOS and Android only**. 
Desktop platforms (Linux, macOS, Windows), Web platform, and test files have been removed to streamline the project for mobile development.

## Getting Started

### Prerequisites
- Flutter SDK 3.7.2 or higher
- iOS development: Xcode 16.2 or higher
- Android development: Android Studio with Android SDK

### Installation

1. Clone the repository
2. Navigate to the tiking directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```

### Building

**Android:**
```bash
flutter build apk --debug
```

**iOS:**
```bash
flutter build ios --debug --no-codesign
```

### Running

**Android:**
```bash
flutter run android
```

**iOS:**
```bash
flutter run ios
```

## Development Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
