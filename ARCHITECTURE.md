# Architecture Overview - Incognito Chats

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT SIDE                              │
│                     (Flutter Mobile App)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Screens    │  │  Providers   │  │   Services   │          │
│  ├──────────────┤  ├──────────────┤  ├──────────────┤          │
│  │ - Login      │  │ - App        │  │ - Auth       │          │
│  │ - Register   │  │ - Chat       │  │ - User       │          │
│  │ - Home       │  │              │  │ - Chat       │          │
│  │ - Chat       │  │ (State Mgmt) │  │ - Socket     │          │
│  │ - Profile    │  │              │  │ - Storage    │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                  │                   │
│         └─────────────────┴──────────────────┘                   │
│                          │                                        │
│                   ┌──────┴───────┐                               │
│                   │              │                                │
│              ┌────▼────┐   ┌─────▼─────┐                        │
│              │  HTTP   │   │  WebSocket │                        │
│              │  API    │   │  Socket.IO │                        │
│              └────┬────┘   └─────┬─────┘                        │
│                   │              │                                │
│              ┌────▼──────────────▼─────┐                        │
│              │  Local Storage (Hive)   │                        │
│              │  - Conversations         │                        │
│              │  - Messages (cached)     │                        │
│              └─────────────────────────┘                        │
└───────────────────┬──────────────┬──────────────────────────────┘
                    │              │
                    │ REST API     │ WebSocket
                    │              │
┌───────────────────▼──────────────▼──────────────────────────────┐
│                        SERVER SIDE                                │
│                  (Node.js + Express + Socket.IO)                 │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Routes     │  │ Controllers  │  │  Middleware  │          │
│  ├──────────────┤  ├──────────────┤  ├──────────────┤          │
│  │ /auth        │─▶│ authCtrl     │  │ JWT Auth     │          │
│  │ /users       │─▶│ userCtrl     │  │ Validation   │          │
│  │ /chat        │─▶│ chatCtrl     │  │ Error Handle │          │
│  └──────────────┘  └──────┬───────┘  └──────────────┘          │
│                           │                                       │
│                    ┌──────▼───────┐                              │
│                    │   Models     │                              │
│                    ├──────────────┤                              │
│                    │ User         │                              │
│                    │ Conversation │                              │
│                    │ Message      │                              │
│                    └──────┬───────┘                              │
│                           │                                       │
│  ┌────────────────────────┴────────────────────────┐            │
│  │          Sequelize ORM                           │            │
│  └────────────────────┬─────────────────────────────┘            │
│                       │                                           │
│  ┌────────────────────▼─────────────────────────────┐            │
│  │        PostgreSQL Database                       │            │
│  ├──────────────────────────────────────────────────┤            │
│  │ Tables:                                           │            │
│  │  - users (id, email, password, displayName, ...)  │            │
│  │  - conversations (id, participant1Id, ...)        │            │
│  │  - messages (id, content, expiresAt, ...)         │            │
│  └──────────────────────────────────────────────────┘            │
│                                                                   │
│  ┌──────────────────────────────────────────────────┐            │
│  │      Background Jobs (node-cron)                 │            │
│  ├──────────────────────────────────────────────────┤            │
│  │  - Message Cleanup (runs every hour)             │            │
│  │  - Deletes expired messages (> 12 hours)         │            │
│  └──────────────────────────────────────────────────┘            │
│                                                                   │
│  ┌──────────────────────────────────────────────────┐            │
│  │      WebSocket Handler (Socket.IO)               │            │
│  ├──────────────────────────────────────────────────┤            │
│  │  Events:                                          │            │
│  │  - authenticate                                   │            │
│  │  - joinConversation                               │            │
│  │  - sendMessage → broadcast to room                │            │
│  │  - deleteMessage → broadcast to room              │            │
│  └──────────────────────────────────────────────────┘            │
└───────────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. User Registration Flow
```
User Input (Email/Password)
    │
    ▼
RegisterScreen
    │
    ▼
AppProvider.register()
    │
    ▼
AuthService.register()
    │
    ▼
POST /api/auth/register
    │
    ▼
authController.register()
    │
    ▼
User.create() [Sequelize]
    │
    ▼
PostgreSQL (users table)
    │
    ▼
JWT Token Generated
    │
    ▼
Response with token + user data
    │
    ▼
Save to SharedPreferences
    │
    ▼
Navigate to HomeScreen
```

### 2. Real-time Message Flow
```
User types message
    │
    ▼
ChatScreen
    │
    ▼
ChatProvider.sendMessage()
    │
    ▼
SocketService.sendMessage()
    │
    ▼
WebSocket: emit('sendMessage')
    │
    ▼
SocketHandler (server)
    │
    ▼
Message.create() [Sequelize]
    │
    ▼
PostgreSQL (messages table)
    │
    ▼
WebSocket: emit('newMessage') to room
    │
    ├──▶ Sender's device
    │    │
    │    ▼
    │    ChatProvider updates messages[]
    │    │
    │    ▼
    │    UI updates (message appears)
    │
    └──▶ Receiver's device
         │
         ▼
         ChatProvider updates messages[]
         │
         ▼
         UI updates (message appears)
         │
         ▼
         StorageService.saveMessage()
         │
         ▼
         Hive (local storage)
```

### 3. Message Expiry Flow
```
Message Created
    │
    ▼
expiresAt = createdAt + 12 hours
    │
    ▼
Stored in PostgreSQL
    │
    ▼
... 12 hours pass ...
    │
    ▼
Cron Job runs (every hour)
    │
    ▼
MessageCleanup.run()
    │
    ▼
DELETE messages WHERE expiresAt < NOW()
    │
    ▼
PostgreSQL removes expired messages
    │
    ▼
Client checks message.isExpired
    │
    ▼
Filters out expired messages in UI
    │
    ▼
StorageService.cleanupExpiredMessages()
    │
    ▼
Hive removes local expired messages
```

## Component Responsibilities

### Frontend (Flutter)

#### Screens (UI Layer)
- **Purpose:** Display UI and handle user interactions
- **Responsibility:** Presentation only, no business logic
- **Example:** LoginScreen, ChatScreen, ProfileScreen

#### Providers (State Management)
- **Purpose:** Manage application state
- **Responsibility:** Coordinate between services and UI
- **Example:** AppProvider, ChatProvider

#### Services (Business Logic)
- **Purpose:** API calls, WebSocket, local storage
- **Responsibility:** Data fetching, caching, real-time communication
- **Example:** AuthService, ChatService, SocketService, StorageService

#### Models (Data)
- **Purpose:** Data structures
- **Responsibility:** Define data shape with type safety
- **Example:** UserModel, ConversationModel, MessageModel

### Backend (Node.js)

#### Routes (API Endpoints)
- **Purpose:** Define API endpoints
- **Responsibility:** Map URLs to controllers
- **Example:** /api/auth/login, /api/chat/conversations

#### Controllers (Request Handlers)
- **Purpose:** Handle HTTP requests
- **Responsibility:** Validate input, call models, return responses
- **Example:** authController, chatController

#### Models (Database)
- **Purpose:** Database schema and queries
- **Responsibility:** Define tables, relationships, validations
- **Example:** User, Conversation, Message

#### Middleware (Cross-cutting)
- **Purpose:** Common functionality for all routes
- **Responsibility:** Authentication, validation, error handling
- **Example:** authMiddleware

#### Socket Handler (Real-time)
- **Purpose:** WebSocket communication
- **Responsibility:** Handle real-time events, broadcast messages
- **Example:** SocketHandler

## Security Architecture

```
┌─────────────────────────────────────────────┐
│           Security Layers                    │
├─────────────────────────────────────────────┤
│                                              │
│  1. Authentication                           │
│     ├─ JWT Tokens                            │
│     ├─ Password Hashing (bcrypt)            │
│     └─ Token Validation Middleware          │
│                                              │
│  2. Privacy                                  │
│     ├─ Email Hidden from API responses      │
│     ├─ Anonymous Display Names              │
│     ├─ No User Activity Tracking            │
│     └─ Screenshot Detection                 │
│                                              │
│  3. Data Protection                          │
│     ├─ Message Auto-Expiry (12h)            │
│     ├─ No Permanent Storage                 │
│     ├─ Automatic Cleanup Job                │
│     └─ Local Storage Encryption (Hive)      │
│                                              │
│  4. Network Security                         │
│     ├─ HTTPS (Production)                   │
│     ├─ CORS Configuration                   │
│     ├─ Input Validation                     │
│     └─ SQL Injection Prevention (Sequelize) │
│                                              │
└─────────────────────────────────────────────┘
```

## Technology Stack Summary

### Frontend
```
Flutter (UI Framework)
    ├── Dart (Programming Language)
    ├── Provider (State Management)
    ├── Hive (Local Storage)
    ├── http (REST API Client)
    ├── socket_io_client (WebSocket Client)
    └── screenshot_callback (Privacy Feature)
```

### Backend
```
Node.js (Runtime)
    ├── Express (Web Framework)
    ├── Sequelize (ORM)
    ├── Socket.IO (WebSocket Server)
    ├── JWT (Authentication)
    ├── bcryptjs (Password Hashing)
    └── node-cron (Scheduled Jobs)
```

### Database
```
PostgreSQL
    ├── users table
    ├── conversations table
    └── messages table
```

## Deployment Architecture (Future)

```
┌─────────────────────────────────────────────┐
│              Mobile Apps                     │
│     (Android/iOS Play Store/App Store)      │
└───────────────┬─────────────────────────────┘
                │ HTTPS + WSS
                │
┌───────────────▼─────────────────────────────┐
│           Load Balancer (Nginx)             │
└───────────────┬─────────────────────────────┘
                │
        ┌───────┴───────┐
        │               │
┌───────▼──────┐ ┌──────▼───────┐
│  Node.js     │ │  Node.js     │
│  Instance 1  │ │  Instance 2  │
└───────┬──────┘ └──────┬───────┘
        │               │
        └───────┬───────┘
                │
┌───────────────▼─────────────────────────────┐
│      PostgreSQL (Primary + Replica)         │
└─────────────────────────────────────────────┘
```

---

**This architecture provides:**
- ✅ Scalability (can add more backend instances)
- ✅ Privacy (no tracking, temporary storage)
- ✅ Real-time (WebSocket for instant messages)
- ✅ Reliability (background cleanup jobs)
- ✅ Security (JWT, password hashing, input validation)
- ✅ Clean separation of concerns
