# Platform-Specific Configuration

## Android Configuration

### 1. Internet Permission
Already configured in `android/app/src/main/AndroidManifest.xml`

Add if missing:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### 2. Prevent Screenshots (Limited Support)
Add to `AndroidManifest.xml` inside `<application>` tag:
```xml
<activity>
    <meta-data
        android:name="io.flutter.embedding.android.EnableScreenshots"
        android:value="false" />
</activity>
```

Or add to MainActivity.kt:
```kotlin
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onResume() {
        super.onResume()
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
}
```

### 3. Image Picker Permissions
Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

### 4. Network Security Config (for HTTP in development)
Create `android/app/src/main/res/xml/network_security_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

Add to `AndroidManifest.xml` in `<application>` tag:
```xml
android:networkSecurityConfig="@xml/network_security_config"
```

### 5. Update Minimum SDK
In `android/app/build.gradle`:
```gradle
defaultConfig {
    minSdkVersion 21  // Required for most features
    targetSdkVersion 33
}
```

## iOS Configuration

### 1. Network Permissions
Add to `ios/Runner/Info.plist`:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 2. Camera & Photo Library (for profile pictures)
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to update your profile picture</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to update your profile picture</string>
```

### 3. Background Modes (optional for WebSocket)
Add to `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## Complete AndroidManifest.xml Example

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.incognito_chats">
    
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    
    <application
        android:label="Incognito Chats"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:networkSecurityConfig="@xml/network_security_config"
        android:usesCleartextTraffic="true">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

## Testing Configurations

### Test Network Permission:
```bash
# Run app and check logs for connection errors
flutter run
# Look for "Network unreachable" or similar errors
```

### Test Screenshot Detection:
1. Run app on physical device
2. Take a screenshot
3. Check if alert appears

### Test Image Picker:
1. Go to profile screen
2. Try to upload profile picture
3. Camera/gallery should open

## Troubleshooting

### Android: "Cleartext HTTP traffic not permitted"
**Solution:** Add network security config (see above)

### iOS: "No permission to access camera"
**Solution:** Add camera usage description to Info.plist

### Android: "Package conflict"
**Solution:** Run `flutter clean && flutter pub get`

### WebSocket not connecting on Android
**Solution:** 
1. Use `10.0.2.2` instead of `localhost`
2. Check network security config allows HTTP
3. Verify backend is accessible from emulator

## Production Recommendations

### Android:
1. ✅ Enable ProGuard for code obfuscation
2. ✅ Remove network security config (use HTTPS only)
3. ✅ Enable FLAG_SECURE for screenshot prevention
4. ✅ Set proper app signing
5. ✅ Use release build configuration

### iOS:
1. ✅ Remove NSAllowsArbitraryLoads (use HTTPS only)
2. ✅ Configure proper app signing & provisioning
3. ✅ Test on multiple iOS versions
4. ✅ Enable App Transport Security
5. ✅ Add proper usage descriptions

## Build Commands

### Debug Build:
```bash
# Android
flutter build apk --debug

# iOS
flutter build ios --debug
```

### Release Build:
```bash
# Android
flutter build apk --release
flutter build appbundle --release  # For Play Store

# iOS
flutter build ios --release
```

### Install on Device:
```bash
# Android
flutter install

# iOS (via Xcode)
open ios/Runner.xcworkspace
# Then build and run from Xcode
```

## App Icons & Splash Screen

### Generate App Icons:
1. Create 1024x1024 icon
2. Use https://appicon.co or similar
3. Replace icons in:
   - `android/app/src/main/res/mipmap-*/ic_launcher.png`
   - `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Splash Screen:
Configure in:
- `android/app/src/main/res/drawable/launch_background.xml`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/`

Or use flutter_native_splash package:
```yaml
flutter_native_splash:
  color: "#1A1A1A"
  image: assets/splash_logo.png
  android: true
  ios: true
```

Then run: `flutter pub run flutter_native_splash:create`
