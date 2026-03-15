# JumpTrack

JumpTrack is a volleyball athlete performance app built with Flutter for Android and iPhone. It combines onboarding, nutrition targets, hydration tracking, workout planning, vertical jump analytics, routines, calendar scheduling, and Firebase-backed cloud sync.

## Features

- Email/password login + Google sign-in with Firebase Authentication
- Firestore persistence for users, workouts, meals, hydration logs, jump records, calendar events, schedules, and routine tasks
- Athlete onboarding with automatic nutrition, hydration, and training recommendations
- Mifflin-St Jeor nutrition calculations with match-day adjustments
- Open Food Facts barcode scanning and meal tracking
- Water tracking + local reminders
- Workout builder with in-app YouTube and TikTok playback
- AI jump estimation using MediaPipe Pose via `flutter_pose_detection`
- Weekly routine scoring and calendar-driven match logic
- Local cache fallback and demo mode for development before Firebase is configured

## Run

```bash
flutter pub get
flutter run
```

## Firebase setup

The project includes placeholder Firebase options so the app can still open in demo mode.

To enable real cloud sync:

1. Run `flutterfire configure`
2. Replace `lib/firebase_options.dart`
3. Add `android/app/google-services.json`
4. Add `ios/Runner/GoogleService-Info.plist`
5. Enable Email/Password and Google sign-in inside Firebase Authentication
6. Create Firestore and Firebase Storage

## Platform requirements

- Android min SDK 31
- iOS 14.0+

Those requirements match the MediaPipe pose detection dependency used for AI jump analysis.
