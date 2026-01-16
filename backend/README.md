# Incognito Chats Backend

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create `.env` file (copy from `.env.example`):
```bash
cp .env.example .env
```

3. Configure your database credentials in `.env`

4. Make sure PostgreSQL is running

5. Start the server:
```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user (requires auth)

### Users
- `GET /api/users/profile` - Get user profile (requires auth)
- `PUT /api/users/profile` - Update profile (requires auth)
- `POST /api/users/profile/picture` - Upload profile picture (requires auth)
- `DELETE /api/users/profile/picture` - Delete profile picture (requires auth)
- `GET /api/users/search?query=name` - Search users by display name (requires auth)

### Chat
- `GET /api/chat/conversations` - Get all conversations (requires auth)
- `POST /api/chat/conversations` - Create/get conversation with user (requires auth)
- `GET /api/chat/conversations/:id/messages` - Get messages (requires auth)
- `DELETE /api/chat/conversations/:id` - Delete conversation (requires auth)
- `DELETE /api/chat/messages/:id` - Delete message (requires auth)

## WebSocket Events

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

## Features

- Email/password authentication
- Anonymous display names
- Profile management
- Real-time messaging via WebSockets
- Automatic message expiry (12 hours)
- Message cleanup job (runs every hour)
- Privacy-focused (no online status, last seen, etc.)
