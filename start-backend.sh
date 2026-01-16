#!/bin/bash

# Backend Development Script
# Starts the backend server with proper environment

cd backend

echo "🚀 Starting Incognito Chats Backend..."
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "Creating from .env.example..."
    cp .env.example .env
    echo "⚠️  Please update .env with your database credentials"
    exit 1
fi

# Check if node_modules exists
if [ ! -d node_modules ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Start the server
npm run dev
