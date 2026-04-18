# Right Now

**Intent-first, identity-delayed connection platform**

Users post what they want *right now*, discover others by intent (no photos), match mutually, then reveal identity and chat within time constraints.

---

## Tech Stack

- **Frontend:** Flutter 3.41.x (Dart)
- **Backend:** Firebase (Auth, Firestore, Cloud Functions, FCM, Storage)

---

## Project Structure

```
lib/
├── main.dart                  # App entry point
├── app.dart                   # Root widget with providers
├── config/
│   ├── constants.dart         # App constants, enums
│   ├── theme.dart             # Dark theme + design tokens
│   └── routes.dart            # GoRouter configuration
├── models/                    # Data models (Firestore serialization)
├── services/                  # Firebase service layer
├── providers/                 # State management (ChangeNotifier)
├── screens/                   # All UI screens
│   ├── auth/                  # Phone OTP login
│   ├── onboarding/            # Profile, photos, verification
│   ├── home/                  # Home shell + post intent
│   ├── feed/                  # Intent feed
│   ├── matches/               # Match list
│   ├── chat/                  # Chat list + chat screen
│   ├── profile/               # User profile
│   └── settings/              # Settings + mode toggle
├── widgets/                   # Reusable widgets
└── utils/                     # Validators, content filter, time utils

firebase/
├── firestore.rules            # Security rules
├── firestore.indexes.json     # Composite indexes
├── storage.rules              # Profile & Photo storage security
└── functions/
    └── src/
        ├── index.ts           # Function exports
        ├── matching.ts        # Mutual match detection
        ├── expiry.ts          # Post + chat expiry jobs
        ├── notifications.ts   # FCM push notifications
        └── moderation.ts      # Auto-flagging
```

---

## Prerequisites

1. **Flutter SDK** (3.41+): https://docs.flutter.dev/get-started/install
2. **Firebase CLI**: `npm install -g firebase-tools`
3. **Node.js** 18+
4. **Xcode** (for iOS) / **Android Studio** (for Android)

---

## Setup Instructions

### 1. Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project called "Right Now"
3. Enable these services:
   - **Authentication** → Phone sign-in method
   - **Cloud Firestore** → Create database (Start in production mode)
   - **Cloud Storage** → Enable
   - **Cloud Messaging** → Enable

### 2. Add Firebase to Flutter

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (generates firebase_options.dart)
flutterfire configure --project=YOUR_PROJECT_ID
```

This will generate `lib/firebase_options.dart`. Then update `main.dart`:

```dart
import 'firebase_options.dart';

// In main():
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

### 3. Install Flutter Dependencies

```bash
flutter pub get
```

### 4. Deploy Firebase Security Rules & Indexes

```bash
firebase login
firebase deploy --only firestore:rules,firestore:indexes,storage
```

### 5. Deploy Cloud Functions

```bash
cd firebase/functions
npm install
npm run build
cd ../..
firebase deploy --only functions
```

### 6. Run the App

```bash
# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android

# List devices
flutter devices
```

---

## Core Features

| Feature | Status |
|---------|--------|
| Phone OTP Auth | ✅ |
| User Profile + Photos | ✅ |
| Selfie Verification (MVP auto-verify) | ✅ |
| Dual Mode (Safe / Open) | ✅ |
| Intent Post System (60min expiry) | ✅ |
| Intent Feed (no photos) | ✅ |
| "I'm in" Interest (silent) | ✅ |
| Mutual Matching (Cloud Function) | ✅ |
| Photo Reveal on Match | ✅ |
| Time-bound Chat (2h + 60min) | ✅ |
| Content Filtering (URLs, phones, socials) | ✅ |
| Report & Block | ✅ |
| FCM Notifications (match + message) | ✅ |
| Post/Chat Expiry Engine | ✅ |
| Firestore Security Rules | ✅ |

---

## Dual Mode System

| | Safe Mode (default) | Open Mode |
|---|---|---|
| Intents | Talk, Meet, Date | Talk, Meet, Date, Open |
| Content | No sexual context | Adult intent (text only) |
| Visibility | Safe users only | Safe + Open users |
| Separation | **HARD** — Safe never sees Open | Configurable |

---

## Key Constraints

- ❌ No swipe UI
- ❌ No photos before match
- ❌ No media sharing in chat
- ❌ No social handle sharing
- ❌ No links in messages
- ❌ Safe and Open users never mix (unless Open mode enabled)
- ✅ One active intent per user
- ✅ Max 80 characters per intent
- ✅ Max 3 photos per profile
- ✅ Chats auto-expire

---

## Environment Variables

No `.env` needed for MVP. Firebase config is handled by FlutterFire CLI.

---

## Testing

```bash
# Static analysis
flutter analyze

# Unit tests
flutter test

# Build verification
flutter build apk --debug
flutter build ios --no-codesign
```

---

## Architecture Decisions

1. **Denormalized posts**: User data (name, age, gender, preferences, content_mode) is denormalized into post documents to avoid N+1 reads in feed queries.

2. **Client-side + server-side filtering**: Firestore query handles mode isolation (safe/open); client-side code handles gender preference cross-matching and couples visibility.

3. **Cloud Functions for matches**: Match creation is server-side only to prevent spoofing. The `onInterestCreate` trigger atomically creates both match and chat documents.

4. **Content filtering**: All messages stream exclusively through the `sendMessage` Callable Cloud Function in the backend, completely blocking clients from manipulating payload contents directly (no URLs/phone numbers server-enforced).

5. **Server-enforced lifecycle update**: Client update rights are completely disabled on core architecture models. `Chats` and `Posts` time out algorithmically via scheduled jobs, with modifying mutations restricted via explicit Differential field `.hasOnly()` restrictions.

6. **Scheduled expiry**: Cloud Functions run every 5 minutes to expire posts (60min) and chats (inactivity-based).

---

## License

Confidential — © 2026 Rahul Menon. All rights reserved.
