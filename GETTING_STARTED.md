# 🎯 Getting Started - Incognito Chats

## 📋 What You Need

Before starting, ensure you have:
- [ ] A computer (Linux, macOS, or Windows)
- [ ] Internet connection
- [ ] At least 5GB free disk space
- [ ] 30-45 minutes for complete setup

## 🔧 Install Prerequisites

### 1. Install Node.js (Backend)
**Linux:**
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**macOS:**
```bash
brew install node
```

**Windows:**
Download from https://nodejs.org/ (LTS version)

**Verify:**
```bash
node --version  # Should show v16.x or higher
npm --version   # Should show v8.x or higher
```

### 2. Install PostgreSQL (Database)
**Linux:**
```bash
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**macOS:**
```bash
brew install postgresql
brew services start postgresql
```

**Windows:**
Download from https://www.postgresql.org/download/windows/

**Verify:**
```bash
psql --version  # Should show PostgreSQL 12.x or higher
```

### 3. Install Flutter (Frontend)
**Linux:**
```bash
# Download Flutter SDK
cd ~/
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# Install dependencies
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
```

**macOS:**
```bash
# Download Flutter SDK
cd ~/
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

**Windows:**
1. Download Flutter SDK from https://docs.flutter.dev/get-started/install/windows
2. Extract to C:\flutter
3. Add C:\flutter\bin to PATH

**Verify:**
```bash
flutter doctor
```

Fix any issues reported by `flutter doctor`:
- Android Studio (recommended) or VS Code with Flutter extension
- Android SDK
- Android device/emulator OR iOS simulator (macOS only)

### 4. Install Git
**Linux:**
```bash
sudo apt-get install git
```

**macOS:**
```bash
brew install git
```

**Windows:**
Download from https://git-scm.com/download/win

**Verify:**
```bash
git --version
```

## 🚀 Setup Project

### Option 1: Automated Setup (Recommended)

```bash
# Navigate to project directory
cd /path/to/incognito_chats

# Run setup script
./setup.sh

# Follow the prompts
```

The script will:
- ✅ Check all prerequisites
- ✅ Create PostgreSQL database
- ✅ Install backend dependencies
- ✅ Create .env file
- ✅ Install Flutter dependencies
- ✅ Generate Hive adapters
- ✅ Run Flutter doctor

### Option 2: Manual Setup

**Step 1: Setup Database**
```bash
# Create database
createdb incognito_chats

# Or if you need to use sudo
sudo -u postgres createdb incognito_chats

# Verify
psql -l | grep incognito_chats
```

**Step 2: Setup Backend**
```bash
cd backend

# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Edit .env with your settings
nano .env  # or your preferred editor
```

Update `.env`:
```env
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=incognito_chats
DB_USER=postgres
DB_PASSWORD=your_postgres_password
JWT_SECRET=generate_a_random_secret_key_here
MESSAGE_EXPIRY_HOURS=12
```

**Step 3: Setup Flutter**
```bash
# Return to project root
cd ..

# Install dependencies
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 4: Configure Backend URL**
Edit `lib/config/config.dart`:
```dart
static const String baseUrl = 'http://localhost:3000';  // For iOS simulator
// OR
static const String baseUrl = 'http://10.0.2.2:3000';   // For Android emulator
```

## ▶️ Run the Application

### Terminal 1: Start Backend
```bash
cd backend
npm run dev
```

You should see:
```
Server is running on port 3000
WebSocket server is ready
Database connection established successfully.
Message cleanup job scheduled
```

### Terminal 2: Start Flutter App
```bash
# List available devices
flutter devices

# Run on connected device/emulator
flutter run

# Or specify device
flutter run -d <device-id>
```

## ✅ Verify Everything Works

### Test 1: Backend Health Check
```bash
curl http://localhost:3000/health
```
Expected: `{"status":"ok","timestamp":"..."}`

### Test 2: Create Test User (Optional)
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```
Expected: JSON with token and user data

### Test 3: App Loads
1. App opens showing login screen ✅
2. No error messages ✅
3. UI looks correct ✅

## 🎮 First Time Using the App

### 1. Register an Account
- Open the app
- Click "Register"
- Enter email: `yourname@example.com`
- Enter password: `password123` (or stronger)
- Click "Register"
- You'll get a random anonymous name like "ShadowWolf4231"

### 2. Edit Your Profile
- Click profile icon (top right)
- Edit display name if you want
- Add a bio (optional)
- Profile picture upload (coming soon)

### 3. Start a Conversation
- Click the + button (bottom right)
- Search for users (you'll need a second account to test)
- Click on a user to start chatting

### 4. Test Real-time Messaging
**Best way:** Use two devices/emulators
1. Register two accounts (different emails)
2. Login on both devices
3. Start conversation from one device
4. Send messages - they should appear instantly on both!

**Alternative:** Use two browsers (for backend testing)
```bash
# Terminal 1
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@test.com","password":"test123"}'

# Terminal 2
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"bob@test.com","password":"test123"}'
```
Then login with both accounts in the app

## 🔍 Troubleshooting

### Problem: "Connection refused" in Flutter app
**Solutions:**
1. Check backend is running: `curl http://localhost:3000/health`
2. For Android emulator, use `http://10.0.2.2:3000` in config.dart
3. For iOS simulator, use `http://localhost:3000`
4. For physical device, use your computer's IP (find with `ifconfig` or `ipconfig`)

### Problem: Database connection error
**Solutions:**
1. Check PostgreSQL is running: `sudo systemctl status postgresql` (Linux)
2. Verify database exists: `psql -l | grep incognito_chats`
3. Check credentials in backend/.env
4. Try: `createdb incognito_chats`

### Problem: "Hive adapter not found" error
**Solution:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Problem: Flutter app won't build
**Solutions:**
1. Run: `flutter clean`
2. Run: `flutter pub get`
3. Run: `flutter doctor` and fix issues
4. Check Android/iOS setup

### Problem: Backend crashes on start
**Solutions:**
1. Check Node version: `node --version` (needs 16+)
2. Delete node_modules: `rm -rf backend/node_modules && cd backend && npm install`
3. Check PostgreSQL is accessible
4. Verify .env file is correct

### Problem: Messages not appearing in real-time
**Solutions:**
1. Check backend logs for WebSocket errors
2. Verify network connectivity
3. Restart both backend and Flutter app
4. Check firewall settings

### Problem: Can't connect from physical device
**Solutions:**
1. Find your computer's IP: `ifconfig` (Linux/Mac) or `ipconfig` (Windows)
2. Update config.dart: `static const String baseUrl = 'http://YOUR_IP:3000';`
3. Ensure computer and phone are on same network
4. Check firewall allows port 3000

## 📱 Development Tips

### Hot Reload (Flutter)
- Press `r` in terminal for hot reload
- Press `R` for hot restart
- Press `q` to quit

### Backend Auto-reload
- Backend uses nodemon, auto-reloads on file changes
- Check terminal for any errors

### Database Commands
```bash
# Connect to database
psql incognito_chats

# View tables
\dt

# View users
SELECT id, email, "displayName" FROM users;

# View messages
SELECT * FROM messages ORDER BY "createdAt" DESC LIMIT 10;

# Clear all data (careful!)
TRUNCATE users, conversations, messages CASCADE;

# Exit
\q
```

### Flutter Commands
```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# List devices
flutter devices

# Run on specific device
flutter run -d chrome  # Web
flutter run -d emulator-5554  # Android
```

## 📚 Next Steps

Once everything is running:

1. **Read the Documentation:**
   - `README.md` - Overview
   - `QUICKSTART.md` - Quick start
   - `PROJECT_SUMMARY.md` - What was built
   - `backend/README.md` - API docs

2. **Explore the Code:**
   - Backend: `backend/`
   - Flutter: `lib/`
   - Models: `lib/models/`
   - Services: `lib/services/`
   - UI: `lib/screens/`

3. **Test Features:**
   - Registration/Login
   - Profile editing
   - User search
   - Real-time chat
   - Message expiry (after 12 hours)
   - Screenshot detection

4. **Customize:**
   - Change colors in `lib/config/theme.dart`
   - Update expiry time in `backend/.env`
   - Modify UI in `lib/screens/`

## 🎓 Learning Resources

- **Flutter:** https://flutter.dev/docs
- **Node.js:** https://nodejs.org/docs
- **Express:** https://expressjs.com/
- **Sequelize:** https://sequelize.org/docs
- **Socket.IO:** https://socket.io/docs
- **Provider:** https://pub.dev/packages/provider
- **Hive:** https://docs.hivedb.dev/

## 💬 Get Help

If you're stuck:
1. Check error messages in terminal
2. Read the documentation files
3. Run `flutter doctor` for Flutter issues
4. Check PostgreSQL logs: `/var/log/postgresql/`
5. Review backend logs in terminal

## ✨ You're Ready!

Congratulations! You now have a fully functional privacy-focused chat application running locally. 

**Enjoy coding! 🕵️‍♂️**
