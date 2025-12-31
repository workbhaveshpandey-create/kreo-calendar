# Kreo Calendar App

A premium cross-platform calendar application built with Flutter, featuring Firebase sync and Google Calendar integration.

## Features

✨ **Beautiful UI** - Modern glassmorphism design with smooth animations  
📱 **Cross-Platform** - Works on Android, iOS, macOS, Windows, and Web  
🔄 **Real-time Sync** - Firebase Firestore keeps your data synced across all devices  
📅 **Google Calendar** - Connect and sync with your Google Calendar  
🔒 **Secure** - Google Sign-In authentication with private user data isolation  

## Setup Instructions

### Prerequisites

- Flutter SDK 3.10 or higher
- A Google account
- Firebase account (free tier works!)

### Step 1: Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Name it "kreo-calendar" (or any name you prefer)
4. Disable Google Analytics (optional for free tier)
5. Click "Create project"

### Step 2: Configure Firebase Authentication

1. In Firebase Console, go to **Build > Authentication**
2. Click "Get started"
3. Enable **Google** sign-in provider
4. Add your project support email
5. Click "Save"

### Step 3: Configure Firestore Database

1. Go to **Build > Firestore Database**
2. Click "Create database"
3. Choose **Start in test mode** (for development)
4. Select a location close to your users
5. Click "Enable"

### Step 4: Add Firebase to Flutter

Run the FlutterFire CLI to configure your platforms:

```bash
# Install FlutterFire CLI (if not installed)
dart pub global activate flutterfire_cli

# Configure Firebase for your Flutter project
cd kreo-calendar
flutterfire configure
```

This will:
- Create `firebase_options.dart`
- Configure Android, iOS, macOS, Windows, and Web

### Step 5: Enable Platform-Specific Configuration

#### Android
The configuration is mostly automatic. Ensure you have:
- Added your SHA-1 fingerprint in Firebase Console (for Google Sign-In)

Get your SHA-1:
```bash
cd android
./gradlew signingReport
```

#### iOS / macOS
Add the `GoogleService-Info.plist` to your Xcode project:
- Open `ios/Runner.xcworkspace` in Xcode
- Drag `GoogleService-Info.plist` into the Runner folder
- Same for macOS in `macos/Runner.xcworkspace`

Also, add URL schemes for Google Sign-In:
1. Open `ios/Runner/Info.plist`
2. Add the reversed client ID from `GoogleService-Info.plist`

#### Web
Google Sign-In on web requires additional configuration in the Google Cloud Console.

### Step 6: Update main.dart

Uncomment the Firebase options line in `lib/main.dart`:

```dart
import 'firebase_options.dart';

// In main():
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Step 7: Run the App

```bash
# Get dependencies
flutter pub get

# Run on your preferred platform
flutter run -d chrome     # Web
flutter run -d macos      # macOS
flutter run               # Default device (mobile)
```

## Firestore Security Rules

For production, update your Firestore rules to secure user data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Calendars are private to each user
    match /calendars/{calendarId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
    
    // Events are private to each user
    match /events/{eventId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
    
    // User settings
    match /settings/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app/
│   ├── app.dart              # App configuration & routing
│   └── theme/
│       ├── app_colors.dart   # Color palette
│       ├── app_theme.dart    # Theme configuration
│       └── text_styles.dart  # Typography
├── features/
│   ├── auth/
│   │   ├── data/             # Auth repository
│   │   ├── domain/           # User model
│   │   └── presentation/     # Login screen & BLoC
│   └── calendar/
│       ├── data/             # Calendar repository
│       ├── domain/           # Event & Calendar models
│       └── presentation/     # Calendar views & widgets
└── shared/
    ├── widgets/              # Reusable widgets
    └── services/             # Shared services
```

## License

Part of the Kreo Ecosystem - Built with ❤️
