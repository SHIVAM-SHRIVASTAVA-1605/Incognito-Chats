#!/bin/bash
# This script clears the app's Hive storage on the connected Android device

echo "Clearing Hive storage..."

# Stop the app if running
adb shell am force-stop com.example.incognito_chats

# Clear app data (this will clear all local storage including Hive)
adb shell pm clear com.example.incognito_chats

echo "✅ Storage cleared! Restart the app to login again."
