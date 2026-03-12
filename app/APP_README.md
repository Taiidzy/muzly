# Muzly - Minimalist Music Player

A beautiful, minimal music player app built with Flutter, inspired by the night city aesthetic of player.html.

## Features

- **Now Playing Screen**: Beautiful player UI matching the player.html design with night city artwork
- **Home Screen**: Recently played, featured albums, popular playlists, and all tracks
- **Search**: Search for tracks, albums, and artists
- **Library**: Browse your playlists, albums, and artists
- **Background Playback**: Continue listening with screen off or while using other apps
- **Media Notifications**: Control playback from system notifications

## Design

The app strictly follows the design from `player.html`:
- **Colors**: Dark theme with muted blues and grays
- **Typography**: 
  - `Inconsolata` for monospace text
  - `Noto Serif JP` for Japanese text
  - `IM Fell English` for titles
- **Visual Elements**: Night city artwork, waveform visualization, minimal controls

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── track.dart
│   ├── album.dart
│   ├── artist.dart
│   └── playlist.dart
├── services/                 # Business logic and API
│   ├── api_service.dart      # REST API client
│   ├── audio_player_service.dart  # Audio playback
│   └── audio_handler.dart    # Background audio
├── providers/                # State management
│   └── player_provider.dart  # Global player state
├── screens/                  # UI screens
│   ├── main_screen.dart      # Bottom navigation
│   ├── home_screen.dart
│   ├── search_screen.dart
│   ├── library_screen.dart
│   ├── now_playing_screen.dart  # Player UI
│   └── track_list_screen.dart
├── widgets/                  # Reusable widgets
│   ├── mini_player.dart
│   ├── track_list_tile.dart
│   └── skeleton_loader.dart
└── utils/                    # Utilities
    └── app_theme.dart        # Theme configuration
```

## Backend API Configuration

The app expects a REST API backend. Update the base URL in `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://localhost:3000';
```

### Expected API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/tracks` | GET | List all tracks (paginated) |
| `/track/{id}` | GET | Get single track |
| `/albums` | GET | List all albums (paginated) |
| `/album/{id}` | GET | Get album with tracks |
| `/album/{id}/tracks` | GET | Get album tracks |
| `/playlists` | GET | List all playlists (paginated) |
| `/playlist/{id}` | GET | Get playlist with tracks |
| `/playlist/{id}/tracks` | GET | Get playlist tracks |
| `/artists` | GET | List all artists (paginated) |
| `/artist/{id}` | GET | Get artist details |
| `/search?q={query}` | GET | Search tracks, albums, artists |
| `/stream/{trackId}` | GET | Audio stream URL |
| `/health` | GET | Health check endpoint |

### Response Formats

**Track:**
```json
{
  "id": "123",
  "title": "Song Title",
  "artistId": "456",
  "artistName": "Artist Name",
  "albumId": "789",
  "albumName": "Album Name",
  "albumArtUrl": "https://...",
  "audioUrl": "https://...",
  "durationMs": 180000,
  "trackNumber": 1
}
```

**Album:**
```json
{
  "id": "789",
  "title": "Album Title",
  "artistId": "456",
  "artistName": "Artist Name",
  "coverUrl": "https://...",
  "releaseYear": 2024,
  "trackCount": 10,
  "tracks": [...]
}
```

**Playlist:**
```json
{
  "id": "101",
  "title": "Playlist Title",
  "description": "Description",
  "coverUrl": "https://...",
  "creatorName": "Creator",
  "trackCount": 25,
  "tracks": [...]
}
```

**Artist:**
```json
{
  "id": "456",
  "name": "Artist Name",
  "imageUrl": "https://...",
  "bio": "Biography",
  "albumCount": 5,
  "trackCount": 50
}
```

## Getting Started

### Prerequisites

- Flutter SDK 3.11.0 or higher
- Dart SDK 3.11.0 or higher
- Android Studio / Xcode for platform development
- Backend API server running

### Installation

1. Clone the repository
2. Navigate to the app directory:
   ```bash
   cd app
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Configure the backend URL in `lib/services/api_service.dart`
5. Run the app:
   ```bash
   flutter run
   ```

### Platform Configuration

#### Android

The Android manifest is already configured with necessary permissions:
- `INTERNET` - For API access
- `WAKE_LOCK` - For background playback
- `FOREGROUND_SERVICE` - For media notifications

#### iOS

The Info.plist is already configured with:
- `UIBackgroundModes` - Audio background mode
- `NSAppTransportSecurity` - Allows HTTP connections (update for production)

## Dependencies

- **provider** - State management
- **just_audio** - Audio playback
- **audio_service** - Background audio handling
- **dio** - HTTP client
- **cached_network_image** - Image caching
- **google_fonts** - Custom fonts
- **rxdart** - Reactive extensions

## Architecture

The app follows the **MVVM** pattern with Provider for state management:

1. **Models**: Data structures (Track, Album, Artist, Playlist)
2. **Services**: Business logic and API communication
3. **Providers**: State management and UI state
4. **Screens**: UI presentation layer
5. **Widgets**: Reusable UI components

## Customization

### Changing Colors

Edit `lib/utils/app_theme.dart`:

```dart
static const Color bg = Color(0xFF0C0D10);
static const Color surface = Color(0xFF111318);
static const Color accent = Color(0xFF7A8FA6);
```

### Changing Fonts

The app uses Google Fonts. To change fonts, update `app_theme.dart` and add fonts to `pubspec.yaml`.

## Troubleshooting

### No Audio Playing

1. Check backend URL in `api_service.dart`
2. Verify backend is running and accessible
3. Check network permissions
4. Ensure audio stream URLs are valid

### Background Playback Not Working

1. Verify Android manifest permissions
2. Check iOS Info.plist background modes
3. Ensure audio_service is properly initialized

### Build Errors

Run:
```bash
flutter clean
flutter pub get
flutter build apk  # or flutter build ios
```

## License

This project is for educational purposes.

## Credits

Design inspired by the minimal night city player.html aesthetic.
