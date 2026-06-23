# Push Notifications Setup Guide

This guide outlines everything needed to implement push notifications with app badge counts for the Frat Finance Tracker app.

## Overview

Push notifications will allow the app to:
- Send notifications when new dues are created
- Send payment reminders even when the app is closed
- Show badge count on the app icon (iOS/Android)
- Display notifications in the system notification center

---

## Prerequisites

### Required Accounts & Services

1. **Apple Developer Account** (for iOS)
   - Individual or Organization account ($99/year)
   - Must be enrolled in the Apple Developer Program
   - Account URL: https://developer.apple.com

2. **Google Play Console Account** (for Android)
   - One-time fee of $25
   - Account URL: https://play.google.com/console

3. **Firebase Project** (for both platforms)
   - Free to use
   - Required for Firebase Cloud Messaging (FCM)
   - URL: https://console.firebase.google.com

---

## iOS Setup

### Information You'll Need From Xcode

1. **Bundle Identifier**
   - Found in: Xcode → Project → General → Identity
   - Format: `com.yourcompany.fratfinancetracker`
   - Must match exactly in Apple Developer Portal

2. **Team ID**
   - Found in: Xcode → Project → Signing & Capabilities
   - 10-character alphanumeric code
   - Also available in Apple Developer Account

3. **App ID**
   - Created in Apple Developer Portal
   - Links your bundle identifier to push notification capability

### Steps to Enable Push Notifications (iOS)

#### 1. Apple Developer Portal Setup

**Create App ID with Push Notifications:**
1. Log in to https://developer.apple.com/account
2. Go to: Certificates, Identifiers & Profiles
3. Click Identifiers → (+) button
4. Select "App IDs" → Continue
5. Enter:
   - Description: "Frat Finance Tracker"
   - Bundle ID: `com.yourcompany.fratfinancetracker` (use your actual bundle ID)
6. Under Capabilities, check:
   - ✅ Push Notifications
   - ✅ Background Modes
7. Click Continue → Register

**Create APNs Authentication Key:**
1. Still in Certificates, Identifiers & Profiles
2. Go to Keys → (+) button
3. Enter:
   - Key Name: "Frat Finance Tracker Push Key"
   - Check: ✅ Apple Push Notifications service (APNs)
4. Click Continue → Register
5. **IMPORTANT:** Download the `.p8` file immediately
   - File name format: `AuthKey_XXXXXXXXXX.p8`
   - **You can only download this once - save it securely!**
6. Note down:
   - Key ID (shown on the page after creation)
   - Team ID (shown at top right of portal)

#### 2. Xcode Configuration

1. Open your project in Xcode
2. Select your app target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Add "Push Notifications"
6. Add "Background Modes" and check:
   - ✅ Remote notifications

#### 3. Firebase Console Setup (iOS)

1. Go to https://console.firebase.google.com
2. Create a new project or select existing
3. Add iOS app:
   - Click "Add app" → iOS
   - Enter your Bundle ID from Xcode
   - Download `GoogleService-Info.plist`
4. Upload APNs Authentication Key:
   - Go to: Project Settings → Cloud Messaging → Apple app configuration
   - Click "Upload" under APNs Authentication Key
   - Upload your `.p8` file
   - Enter your Key ID and Team ID
5. Download `GoogleService-Info.plist` and add to Xcode project root

---

## Android Setup

### Information You'll Need

1. **Package Name**
   - Found in: `android/app/build.gradle`
   - Look for: `applicationId "com.example.fratfinancetracker"`
   - Must match exactly in Firebase

2. **SHA-1 Certificate Fingerprint**
   - Required for Firebase Authentication
   - Get it by running:
     ```bash
     cd android
     ./gradlew signingReport
     ```
   - Look for SHA-1 under `Variant: debug` or `Variant: release`

### Steps to Enable Push Notifications (Android)

#### 1. Firebase Console Setup (Android)

1. In your Firebase project
2. Add Android app:
   - Click "Add app" → Android
   - Enter Package name: `com.example.fratfinancetracker`
   - Enter SHA-1 certificate fingerprint
   - Download `google-services.json`
3. Place `google-services.json` in: `android/app/` directory

#### 2. Android Configuration Files

**File: `android/app/build.gradle`**
```gradle
dependencies {
    // Add at the bottom
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}

// At the very bottom of the file
apply plugin: 'com.google.gms.google-services'
```

**File: `android/build.gradle`**
```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**File: `android/app/src/main/AndroidManifest.xml`**
```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE" />

    <application>
        <!-- Add this service -->
        <service
            android:name=".Application"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>

        <!-- Add notification icon (optional) -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />

        <!-- Add notification color (optional) -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />
    </application>
</manifest>
```

---

## Flutter Code Implementation

### 1. Add Dependencies

**File: `pubspec.yaml`**
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
```

Run: `flutter pub get`

### 2. Initialize Firebase

**File: `lib/main.dart`**
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permissions (iOS)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const MyApp());
}
```

### 3. Create Notification Service

**File: `lib/shared/services/notification_service.dart`**
```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Navigate to relevant screen
      _handleNotificationTap(message);
    });
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navigate based on notification data
    // Example: context.push('/notifications')
  }
}
```

### 4. Store FCM Tokens in Supabase

Add a column to the `users` table:
```sql
ALTER TABLE users ADD COLUMN fcm_token TEXT;
```

Update token when user logs in:
```dart
// After successful login
final token = await NotificationService().getToken();
if (token != null) {
  await supabase.from('users').update({
    'fcm_token': token,
  }).eq('id', userId);
}
```

---

## Supabase Edge Function for Sending Notifications

### Create Edge Function

**File: `supabase/functions/send-notification/index.ts`**
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const FIREBASE_SERVER_KEY = Deno.env.get('FIREBASE_SERVER_KEY')!

serve(async (req) => {
  const { userIds, title, body, data } = await req.json()

  // Get FCM tokens for users
  const { data: users } = await supabaseClient
    .from('users')
    .select('fcm_token')
    .in('id', userIds)
    .not('fcm_token', 'is', null)

  const tokens = users?.map(u => u.fcm_token) || []

  // Send to FCM
  const response = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Authorization': `key=${FIREBASE_SERVER_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      registration_ids: tokens,
      notification: { title, body },
      data: data || {},
      priority: 'high',
    }),
  })

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

Deploy: `supabase functions deploy send-notification`

Set secret: `supabase secrets set FIREBASE_SERVER_KEY=your_server_key_here`

---

## Testing Checklist

### iOS Testing
- [ ] Simulator: Test notification display (won't receive actual push)
- [ ] Physical device: Test with TestFlight or development build
- [ ] Verify badge count updates on app icon
- [ ] Test notification center display
- [ ] Test notification tap navigation
- [ ] Test background notification reception

### Android Testing
- [ ] Emulator: Test notification display
- [ ] Physical device: Test with debug APK
- [ ] Verify badge count updates (Android 8.0+)
- [ ] Test notification center display
- [ ] Test notification tap navigation
- [ ] Test background notification reception

---

## Information Checklist

Before proceeding, collect:

### For iOS:
- [ ] Bundle Identifier (from Xcode)
- [ ] Team ID (from Apple Developer Portal)
- [ ] APNs Authentication Key (.p8 file)
- [ ] Key ID (from APNs key creation)
- [ ] `GoogleService-Info.plist` (from Firebase)

### For Android:
- [ ] Package Name (from build.gradle)
- [ ] SHA-1 Certificate Fingerprint (from gradlew signingReport)
- [ ] `google-services.json` (from Firebase)

### For Firebase:
- [ ] Firebase project created
- [ ] iOS app added to Firebase
- [ ] Android app added to Firebase
- [ ] Cloud Messaging API enabled
- [ ] Server key (for Supabase Edge Function)

---

## Troubleshooting

### iOS Issues
- **Not receiving notifications**: Check APNs key is uploaded correctly
- **Badge not updating**: Ensure Background Modes capability is enabled
- **Notifications not showing**: Check notification permissions in Settings

### Android Issues
- **Not receiving notifications**: Check google-services.json is in correct location
- **Badge not showing**: Badge support varies by launcher (Samsung, Pixel, etc.)
- **Build errors**: Ensure Google services plugin is applied

### General
- **Token is null**: Check Firebase initialization
- **Notifications work on one platform only**: Check platform-specific setup
- **Background notifications not working**: Verify background handler is set up

---

## Next Steps After Setup

1. Test on both iOS and Android devices
2. Implement notification preferences in user settings
3. Add notification sound customization
4. Set up analytics to track notification engagement
5. Implement notification action buttons (Reply, View, etc.)
6. Add scheduled notifications for due dates
