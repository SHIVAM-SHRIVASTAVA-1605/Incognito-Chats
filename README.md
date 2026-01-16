# 🕵️‍♂️ Incognito Chats

A privacy-focused anonymous chatting application where users can communicate securely, and all messages automatically disappear after 12 hours.

## 🎯 Features

### Authentication & Identity
- ✅ Email & password authentication (no phone number)
- ✅ Unique user ID (UID) for internal identification
- ✅ Email never visible to other users
- ✅ Anonymous display names (randomly generated on signup)

### Profile Management
- ✅ Set/change display name
- ✅ Add optional bio/description
- ✅ Upload, change, or remove profile picture
- ✅ Continue without profile picture

### Chat Features
- ✅ Real-time messaging via WebSockets
- ✅ Messages auto-expire after 12 hours
- ✅ Manual message deletion
- ✅ Manual conversation deletion
- ✅ Offline support with local caching
- ✅ Message list sorted by time

### Privacy & Anonymity
- ✅ No online/offline status
- ✅ No last seen indicators
- ✅ No typing indicators
- ✅ No read receipts
- ✅ No message forwarding
- ✅ Screenshot detection with alerts
- ✅ Clean, minimal, dark-friendly UI

### Message Expiry Logic
- ✅ Each message has creation and expiry timestamps
- ✅ Auto-delete after 12 hours
- ✅ Automatic cleanup job runs hourly on backend
- ✅ Works even when user is offline
- ✅ Local storage respects expiry

## 🏗️ Architecture

### Backend
- **Framework:** Node.js + Express
- **Database:** PostgreSQL with Sequelize ORM
- **Real-time:** Socket.IO for WebSocket connections
- **Authentication:** JWT tokens
- **Password Hashing:** bcryptjs
- **Scheduled Tasks:** node-cron for message cleanup

### Frontend
- **Framework:** Flutter
- **State Management:** Provider
- **Local Storage:** Hive
- **Real-time:** Socket.IO client
- **Screenshot Detection:** screenshot_callback package
- **UI:** Dark theme with neutral colors

## 📁 Project Structure

```
incognito_chats/
├── backend/                    # Node.js backend
│   ├── config/                # Database configuration
│   ├── models/                # Sequelize models (User, Conversation, Message)
│   ├── controllers/           # Business logic
│   ├── routes/                # API endpoints
│   ├── middleware/            # Authentication middleware
│   ├── socket/                # WebSocket handler
│   ├── utils/                 # Message cleanup utilities
│   ├── package.json
│   ├── server.js
│   └── README.md
├── lib/                       # Flutter frontend
│   ├── config/               # App configuration & theme
│   ├── models/               # Data models
│   ├── services/             # API & WebSocket services
│   ├── providers/            # State management
│   ├── screens/              # UI screens
│   ├── widgets/              # Reusable widgets
│   └── main.dart
├── pubspec.yaml
└── README.md
```

## 🚀 Quick Start

### Prerequisites
- Node.js (v16 or higher)
- PostgreSQL database
- Flutter SDK (3.5.3 or higher)
- Android Studio / VS Code

### Backend Setup

1. **Navigate to backend directory:**
```bash
cd backend
```

2. **Install dependencies:**
```bash
npm install
```

3. **Create `.env` file:**
```bash
cp .env.example .env
```

4. **Configure `.env` with your database credentials:**
```env
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=incognito_chats
DB_USER=postgres
DB_PASSWORD=your_password
JWT_SECRET=your_super_secret_jwt_key
MESSAGE_EXPIRY_HOURS=12
```

5. **Start PostgreSQL and create database:**
```bash
createdb incognito_chats
```

6. **Start the server:**
```bash
npm run dev
```

Backend will run on `http://localhost:3000`

### Frontend Setup

1. **Install Flutter dependencies:**
```bash
flutter pub get
```

2. **Generate Hive adapters:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. **Configure backend URL in `lib/config/config.dart`:**
```dart
static const String baseUrl = 'http://10.0.2.2:3000';  // For Android emulator
// OR
static const String baseUrl = 'http://YOUR_IP:3000';   // For physical device
```

4. **Run the app:**
```bash
flutter run
```

## 🔌 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user

### Users
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update profile
- `POST /api/users/profile/picture` - Upload profile picture
- `DELETE /api/users/profile/picture` - Delete profile picture
- `GET /api/users/search?query=name` - Search users

### Chat
- `GET /api/chat/conversations` - Get all conversations
- `POST /api/chat/conversations` - Create/get conversation
- `GET /api/chat/conversations/:id/messages` - Get messages
- `DELETE /api/chat/conversations/:id` - Delete conversation
- `DELETE /api/chat/messages/:id` - Delete message

## 🔐 WebSocket Events

### Client → Server
- `authenticate` - Authenticate with JWT token
- `joinConversation` - Join a conversation room
- `leaveConversation` - Leave a conversation room
- `sendMessage` - Send a message
- `deleteMessage` - Delete a message

### Server → Client
- `authenticated` - Authentication result
- `newMessage` - New message received
- `messageDeleted` - Message was deleted
- `error` - Error occurred

## 🎨 Design Principles

- **Minimal & Distraction-free:** Clean UI without clutter
- **Dark-friendly:** Neutral color palette with dark theme
- **No animations:** Focus on simplicity
- **Privacy-first:** No exposure of user activity
- **Anonymous:** Random names, no identifying information

## 🔒 Privacy Features

1. **Message Expiry:** All messages auto-delete after 12 hours
2. **No Tracking:** No online status, last seen, or typing indicators
3. **Anonymous:** Email addresses never shown to other users
4. **Screenshot Detection:** Alerts users when screenshots are taken
5. **Local Cleanup:** Expired messages removed from local storage
6. **Secure Storage:** Messages stored temporarily only

## 🛠️ Development

### Backend Development
```bash
cd backend
npm run dev  # Runs with nodemon for auto-reload
```

### Frontend Development
```bash
flutter run  # Hot reload enabled
```

### Database Reset
```bash
cd backend
node -e "require('./config/database').sync({ force: true })"
```

## 📝 Testing

### Test Backend API
```bash
curl http://localhost:3000/health
```

### Register User
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

## 🐛 Troubleshooting

### Backend Issues
- Ensure PostgreSQL is running
- Check database credentials in `.env`
- Verify port 3000 is not in use

### Flutter Issues
- Run `flutter doctor` to check setup
- Regenerate Hive adapters if getting errors
- Check backend URL in `config.dart`
- For Android emulator, use `10.0.2.2` instead of `localhost`

## 📚 Tech Stack

**Backend:**
- Node.js
- Express.js
- Sequelize ORM
- PostgreSQL
- Socket.IO
- JWT
- bcryptjs
- node-cron

**Frontend:**
- Flutter
- Provider (State Management)
- Hive (Local Storage)
- Socket.IO Client
- HTTP package
- screenshot_callback

## 🔮 Future Enhancements

- End-to-end encryption
- Push notifications
- Voice messages
- Better screenshot prevention
- Message search
- Group chats
- File sharing (with auto-expiry)

## 📄 License

Private project - All rights reserved

## 👨‍💻 Development Notes

- Backend and frontend are kept separate as per requirements
- Clean architecture with separation of concerns
- Proper state management (no excessive setState)
- Services, models, and controllers clearly defined
- Privacy-focused design throughout

---

**Built with privacy in mind. Your conversations, your control.**
