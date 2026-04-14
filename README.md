# DCA Academy — Student Mobile App (Flutter)

Cross-platform Flutter app for students to access sessions, quizzes, lectures, and live streams from the DCA backend.

## Quick Start

1. **Install dependencies** (the only terminal step):
   ```bash
   cd application-mobile/dca
   flutter pub get
   ```

2. **Configure API base URLs** in `lib/config/api_config.dart`:
   ```dart
   static const String backendBaseUrl = 'https://dca.jantrah.io';
   static const String streamerBaseUrl = 'https://jawab.jantrah.io/media-storage-streamer/api';
   ```

3. **Run**:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                          # App entry, MultiProvider, theme
├── config/
│   ├── api_config.dart                # All endpoint URLs in one place
│   └── app_theme.dart                 # Colors, spacing, ThemeData
├── models/                            # Data classes (User, Quiz, Question, etc.)
├── services/
│   ├── api_service.dart               # http wrapper with Bearer auth
│   ├── auth_service.dart              # login/signup/logout
│   └── storage_service.dart           # SharedPreferences for token+user
├── providers/
│   └── auth_provider.dart             # Auth state via ChangeNotifier
├── widgets/
│   └── common_widgets.dart            # Reusable UI components
└── screens/
    ├── splash_screen.dart             # Entry → routes to login or home
    ├── home_screen.dart               # Bottom nav: Dashboard/Sessions/Quizzes/Lectures/Profile
    ├── dashboard_screen.dart          # Stats, news, recent assignments
    ├── auth/
    │   ├── login_screen.dart
    │   └── signup_screen.dart
    ├── sessions/
    │   ├── sessions_screen.dart       # Tabs: assigned vs other
    │   └── session_quizzes_screen.dart
    ├── quizzes/
    │   ├── quizzes_screen.dart        # All quizzes
    │   ├── quiz_attempt_screen.dart   # Live attempt + timer + skipped mode
    │   ├── quiz_result_screen.dart    # Score circle + filtered Q&A
    │   ├── reattempt_dialog.dart
    │   └── widgets/quiz_card.dart
    ├── lectures/
    │   ├── lectures_screen.dart
    │   └── widgets/lecture_card.dart
    ├── profile/
    │   └── profile_screen.dart        # View + edit
    ├── video_player_screen.dart       # HLS / MP4 via chewie
    ├── live_stream_screen.dart
    └── news_screen.dart
```

## Features

- **Auth**: token-based login/signup with persistent storage
- **Dashboard**: clickable stat tiles, news ticker, recent sessions
- **Sessions**: assigned/other tabs with session info
- **Quizzes**: live countdown timer (timezone-safe), attempt screen with MCQ/True-False/Text questions, skipped mode, instant feedback
- **Quiz Result**: animated score circle, filterable Q&A breakdown
- **Lectures**: cards with auto-generated thumbnails from streamer UUID
- **Video Player**: HLS streaming (works natively on iOS/Android via ExoPlayer/AVPlayer)
- **Live Stream**: live status badge, ticker, opens YouTube/Zoom externally
- **Profile**: view/edit personal info with show/hide password
- **Re-attempt requests**: dialog with reason input
- **Pull-to-refresh** on every list screen
- **Logout** with confirmation

## Architecture Notes

- **State**: lightweight `ChangeNotifier` via `provider` (no Bloc/Riverpod overhead)
- **API**: single `ApiService` with consistent `{ success, data, message }` envelope
- **Storage**: `SharedPreferences` for token + user JSON
- **Theme**: matches the web app design (gradient header, rounded cards, no shadows)
- **Errors**: consistent `LoadingView`/`ErrorView`/`EmptyView` widgets
- **Timezone-safe quiz timer**: server sends `start_time_utc` + `server_now_utc`, client computes clock offset
- **HLS playback**: `video_player` + `chewie` (native HLS support on mobile)

## Required Permissions

For Android, ensure `android/app/src/main/AndroidManifest.xml` has:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

For iOS, `ios/Runner/Info.plist` should allow arbitrary loads if needed:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## Customization

- **Colors**: edit `lib/config/app_theme.dart`
- **API URLs**: edit `lib/config/api_config.dart`
- **Splash logo**: replace `Icons.school` in `splash_screen.dart` and `login_screen.dart`
