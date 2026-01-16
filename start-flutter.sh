#!/bin/bash

# Flutter Development Script
# Runs the Flutter app with proper configuration

echo "📱 Starting Incognito Chats Flutter App..."
echo ""

# Check if Hive adapters are generated
if [ ! -f lib/models/user_model.g.dart ]; then
    echo "⚠️  Hive adapters not found. Generating..."
    flutter pub run build_runner build --delete-conflicting-outputs
fi

# List available devices
echo "Available devices:"
flutter devices
echo ""

# Run the app
flutter run
