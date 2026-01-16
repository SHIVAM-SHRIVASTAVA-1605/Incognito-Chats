#!/bin/bash

# Incognito Chats - Setup Script
# This script sets up both backend and frontend

set -e

echo "🕵️‍♂️  Incognito Chats Setup Script"
echo "================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi
echo -e "${GREEN}✅ Node.js $(node --version)${NC}"

# Check npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ npm $(npm --version)${NC}"

# Check PostgreSQL
if ! command -v psql &> /dev/null; then
    echo -e "${RED}❌ PostgreSQL is not installed${NC}"
    echo "Please install PostgreSQL from https://www.postgresql.org/"
    exit 1
fi
echo -e "${GREEN}✅ PostgreSQL installed${NC}"

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed${NC}"
    echo "Please install Flutter from https://flutter.dev/"
    exit 1
fi
echo -e "${GREEN}✅ Flutter $(flutter --version | head -n 1)${NC}"

echo ""
echo "🗄️  Setting up database..."

# Check if database exists
if psql -lqt | cut -d \| -f 1 | grep -qw incognito_chats; then
    echo -e "${YELLOW}⚠️  Database 'incognito_chats' already exists${NC}"
    read -p "Do you want to drop and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        dropdb incognito_chats
        createdb incognito_chats
        echo -e "${GREEN}✅ Database recreated${NC}"
    fi
else
    createdb incognito_chats
    echo -e "${GREEN}✅ Database created${NC}"
fi

echo ""
echo "🔧 Setting up backend..."

cd backend

# Install dependencies
echo "Installing backend dependencies..."
npm install

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cp .env.example .env
    echo -e "${YELLOW}⚠️  Please update backend/.env with your database credentials${NC}"
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

cd ..

echo ""
echo "📱 Setting up Flutter..."

# Install Flutter dependencies
echo "Installing Flutter dependencies..."
flutter pub get

# Generate Hive adapters
echo "Generating Hive adapters..."
flutter pub run build_runner build --delete-conflicting-outputs

# Run Flutter doctor
echo ""
echo "Running Flutter doctor..."
flutter doctor

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "📝 Next steps:"
echo "1. Update backend/.env with your database credentials"
echo "2. Start backend: cd backend && npm run dev"
echo "3. Update lib/config/config.dart with your backend URL"
echo "4. Run Flutter app: flutter run"
echo ""
echo "📚 For detailed instructions, see QUICKSTART.md"
