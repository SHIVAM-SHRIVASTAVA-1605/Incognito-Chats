# Incognito Chats - Flutter Frontend

A privacy-focused anonymous chatting application built with Flutter.

## Features

✅ **Authentication & Identity**
- Email & password authentication
- Anonymous display names (randomly generated)
- No phone number required
- Email never visible to other users

✅ **Profile Management**
- Set/change display name
- Add optional bio
- Upload, change, or remove profile picture
- Optional profile picture support

✅ **Chat Features**
- Real-time messaging via WebSockets
- Messages auto-expire after 12 hours
- Manual message deletion
- Manual conversation deletion
- Local storage with Hive for offline access

✅ **Privacy & Anonymity**
- No online/offline status
- No last seen
- No typing indicators
- No read receipts
- No message forwarding
- Screenshot detection with notifications
- Dark-friendly, minimal UI

## Setup Instructions

### Prerequisites
- Flutter SDK (3.5.3 or higher)
- Dart SDK
- Android Studio / VS Code
- Backend server running (see backend README)

### Installation

1. **Install dependencies:**
```bash
flutter pub get
```

2. **Generate Hive adapters (required for local storage):**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. **Configure backend URL:**
   
Edit `lib/config/config.dart` and update the URLs:
```dart
static const String baseUrl = 'http://YOUR_BACKEND_IP:3000';
static const String apiUrl = '$baseUrl/api';
static const String wsUrl = 'http://YOUR_BACKEND_IP:3000';
```

For Android emulator: Use `http://10.0.2.2:3000`
For physical device: Use your computer's IP address

4. **Run the app:**
```bash
# Check available devices
flutter devices

# Run on connected device
flutter run

# Or build APK
flutter build apk
```

## Project Structure

```
lib/
├── config/              # App configuration
│   ├── config.dart     # Backend URLs, constants
│   └── theme.dart      # Dark theme configuration
├── models/             # Data models
│   ├── user_model.dart
│   ├── conversation_model.dart
│   └── message_model.dart
├── services/           # Business logic
│   ├── auth_service.dart
│   ├── user_service.dart
│   ├── chat_service.dart
│   ├── socket_service.dart
│   └── storage_service.dart
├── providers/          # State management
│   ├── app_provider.dart
│   └── chat_provider.dart
├── screens/            # UI screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── chat/
│   │   ├── chat_screen.dart
│   │   └── search_users_screen.dart
│   └── profile/
│       └── profile_screen.dart
├── widgets/            # Reusable widgets
│   ├── conversation_tile.dart
│   └── message_bubble.dart
└── main.dart          # App entry point
```

## Architecture

- **State Management:** Provider
- **Local Storage:** Hive (for offline access and message caching)
- **Networking:** HTTP package for REST API
- **Real-time Communication:** Socket.IO client
- **Screenshot Detection:** screenshot_callback package

## Key Features Implementation

### Message Expiry
- Each message has a `createdAt` and `expiresAt` timestamp
- Messages automatically expire after 12 hours
- Expired messages are filtered out from UI
- Local cleanup runs periodically

### Privacy Features
- No data collection beyond necessary authentication
- Messages stored temporarily only
- Email addresses never exposed
- Anonymous display names by default
- Screenshot detection alerts users

### Real-time Messaging
- WebSocket connection for instant message delivery
- Automatic reconnection on network changes
- Message delivery status handling

## Troubleshooting

### Hive Adapters Error
If you get errors about missing adapters:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Connection Issues
- Make sure backend server is running
- Check `lib/config/config.dart` for correct URLs
- For Android emulator, use `10.0.2.2` instead of `localhost`
- For iOS simulator, use `localhost` or your computer's IP

### Screenshot Detection
- Works on most Android devices
- Limited support on iOS
- Some devices may not support this feature

## Privacy Notice

This app implements several privacy features:
- Messages auto-delete after 12 hours
- No permanent message history
- No tracking of user activity
- Screenshot detection (where supported)
- Minimal data collection

## Development Notes

### TODO
- Image upload for profile pictures (currently placeholder)
- Message encryption end-to-end
- Push notifications for new messages
- Better screenshot prevention (OS limitations)
- Message search functionality

### Known Limitations
- Screenshot detection is not 100% reliable
- Cannot completely prevent screenshots on all devices
- WebSocket connection requires stable internet

## License

Private project - All rights reserved
