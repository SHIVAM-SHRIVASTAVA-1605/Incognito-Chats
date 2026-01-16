# Quick Start Guide - Incognito Chats

## Prerequisites Check
- [ ] Node.js installed (v16+)
- [ ] PostgreSQL installed and running
- [ ] Flutter SDK installed (3.5.3+)
- [ ] Android Studio or VS Code with Flutter extension

## Step 1: Database Setup (2 minutes)

```bash
# Start PostgreSQL service
sudo service postgresql start   # Linux
# OR
brew services start postgresql  # macOS

# Create database
createdb incognito_chats

# Verify connection
psql -d incognito_chats -c "SELECT 1;"
```

## Step 2: Backend Setup (3 minutes)

```bash
# Navigate to backend
cd backend

# Install dependencies
npm install

# Create environment file
cat > .env << EOL
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=incognito_chats
DB_USER=postgres
DB_PASSWORD=postgres
JWT_SECRET=change_this_to_random_secret_key_in_production
MESSAGE_EXPIRY_HOURS=12
EOL

# Start backend server
npm run dev
```

✅ Backend should be running on http://localhost:3000

Test it: `curl http://localhost:3000/health`

## Step 3: Flutter Setup (5 minutes)

```bash
# Return to project root
cd ..

# Install dependencies
flutter pub get

# Generate Hive adapters (IMPORTANT!)
flutter pub run build_runner build --delete-conflicting-outputs

# Check Flutter setup
flutter doctor
```

## Step 4: Configure Frontend

Edit `lib/config/config.dart`:

```dart
// For Android Emulator:
static const String baseUrl = 'http://10.0.2.2:3000';

// For iOS Simulator:
static const String baseUrl = 'http://localhost:3000';

// For Physical Device (replace with your computer's IP):
static const String baseUrl = 'http://192.168.1.XXX:3000';
```

To find your IP:
- Linux/Mac: `ifconfig | grep inet`
- Windows: `ipconfig`

## Step 5: Run the App

```bash
# List available devices
flutter devices

# Run on connected device/emulator
flutter run

# OR build APK for Android
flutter build apk
```

## First Time Use

1. **Open the app** - You'll see the login screen
2. **Click "Register"**
3. **Enter email and password** (email format: test@example.com)
4. **You'll get a random anonymous name** (e.g., ShadowWolf1234)
5. **Edit your profile** if you want to change name/bio
6. **Search for users** to start conversations
7. **Send messages** - they'll disappear in 12 hours!

## Testing Locally

### Create Two Users

**User 1:**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@test.com","password":"password123"}'
```

**User 2:**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"bob@test.com","password":"password123"}'
```

Now login with both users in the app (or use two devices/emulators) to test real-time chat!

## Common Issues & Fixes

### ❌ "Connection refused" error in Flutter
**Fix:** Check backend URL in `lib/config/config.dart`
- Android emulator: Use `10.0.2.2:3000`
- iOS simulator: Use `localhost:3000`
- Physical device: Use your computer's local IP

### ❌ Database connection error
**Fix:** 
1. Check PostgreSQL is running: `pg_isready`
2. Verify credentials in `backend/.env`
3. Ensure database exists: `psql -l | grep incognito_chats`

### ❌ "Missing Hive adapter" error
**Fix:** Run Hive code generator:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### ❌ Backend crashes on startup
**Fix:**
1. Check Node version: `node --version` (should be 16+)
2. Delete node_modules and reinstall: `rm -rf node_modules && npm install`
3. Check PostgreSQL connection

### ❌ Messages not appearing in real-time
**Fix:**
1. Check WebSocket connection in app
2. Verify backend is running
3. Check network permissions in Android manifest

## Verify Everything Works

### ✅ Backend Health Check
```bash
curl http://localhost:3000/health
# Should return: {"status":"ok","timestamp":"..."}
```

### ✅ Test Registration
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
# Should return token and user data
```

### ✅ Flutter Build
```bash
flutter build apk --debug
# Should complete without errors
```

## Development Workflow

### Working on Backend:
```bash
cd backend
npm run dev  # Auto-reloads on changes
```

### Working on Flutter:
```bash
flutter run  # Hot reload with 'r', hot restart with 'R'
```

### Viewing Logs:
**Backend:**
```bash
# Terminal where npm run dev is running shows logs
```

**Flutter:**
```bash
# Flutter console shows logs, or use:
flutter logs
```

### Database Management:
```bash
# Connect to database
psql -d incognito_chats

# View tables
\dt

# View users
SELECT id, email, "displayName" FROM users;

# View messages
SELECT id, content, "createdAt", "expiresAt" FROM messages;

# Clear all data (CAREFUL!)
TRUNCATE users, conversations, messages CASCADE;
```

## Production Deployment

### Backend:
1. Use environment variables for sensitive data
2. Enable HTTPS
3. Configure CORS properly
4. Use production database (not localhost)
5. Set strong JWT_SECRET

### Flutter:
1. Update URLs to production backend
2. Build release APK: `flutter build apk --release`
3. Configure app signing for Android
4. Test on multiple devices

## Need Help?

1. Check the main README.md for detailed documentation
2. Check backend/README.md for API documentation
3. Check README_FLUTTER.md for Flutter-specific info
4. Run `flutter doctor` to diagnose Flutter issues
5. Check PostgreSQL logs: `tail -f /var/log/postgresql/postgresql-*.log`

---

**You're all set! Start chatting anonymously! 🕵️‍♂️**
