# App Store & Google Play Store Deployment Guide

This guide covers everything needed to publish the Frat Finance Tracker app to both the Apple App Store and Google Play Store.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Apple App Store Deployment](#apple-app-store-deployment)
3. [Google Play Store Deployment](#google-play-store-deployment)
4. [Post-Deployment](#post-deployment)

---

## Prerequisites

### Required Accounts

#### Apple Developer Program
- **Cost**: $99/year (USD)
- **Sign up**: https://developer.apple.com/programs/
- **Processing time**: 1-2 business days for approval
- **Requirements**:
  - Apple ID
  - Credit card for payment
  - Legal entity information (individual or organization)
  - D-U-N-S Number (if enrolling as organization)

#### Google Play Console
- **Cost**: $25 one-time registration fee
- **Sign up**: https://play.google.com/console/signup
- **Processing time**: Usually instant, up to 48 hours for review
- **Requirements**:
  - Google account
  - Credit card for payment
  - Developer information

### Development Tools

#### For iOS:
- macOS computer (required)
- Xcode 15.0 or later
- Valid Apple Developer account

#### For Android:
- Any OS (macOS, Windows, Linux)
- Android Studio (optional but recommended)
- Java Development Kit (JDK)

---

## Apple App Store Deployment

### Phase 1: Prepare Your App

#### 1. App Information to Collect

**Basic Info:**
- [ ] App Name (30 characters max)
  - Example: "Frat Finance Tracker"
- [ ] Subtitle (30 characters max)
  - Example: "Track fraternity dues & payments"
- [ ] Primary Language
  - Example: English (U.S.)
- [ ] Bundle ID
  - Found in Xcode: Project → General → Identity
  - Format: `com.yourcompany.fratfinancetracker`
  - **Cannot be changed after first submission**
- [ ] SKU (Stock Keeping Unit)
  - Internal identifier, not visible to users
  - Example: "FRATFINANCE001"

**Description & Keywords:**
- [ ] Description (4000 characters max)
  - What the app does
  - Key features
  - Benefits for users
- [ ] Keywords (100 characters max)
  - Comma-separated
  - Example: "fraternity,dues,finance,payment,tracker,college"
- [ ] Promotional Text (170 characters max)
  - Can be updated without new version
  - Example: "Now with push notifications! Stay updated on dues and payments."

**Support Info:**
- [ ] Support URL
  - Example: "https://fratfinancetracker.com/support"
  - Can be a GitHub wiki or simple website
- [ ] Marketing URL (optional)
  - Example: "https://fratfinancetracker.com"
- [ ] Privacy Policy URL (REQUIRED)
  - **Must be publicly accessible**
  - Example: "https://fratfinancetracker.com/privacy"

**Contact Information:**
- [ ] First Name
- [ ] Last Name
- [ ] Phone Number
- [ ] Email Address
  - Will receive important updates from Apple

#### 2. Visual Assets Required

**App Icon:**
- [ ] 1024x1024 pixels
- PNG format
- No transparency
- No rounded corners (Apple adds them)
- Should match icon in app

**Screenshots (REQUIRED for at least one device size):**

**iPhone 6.7" Display (iPhone 15 Pro Max, 14 Pro Max):**
- [ ] 2 - 10 screenshots
- Size: 1290 x 2796 pixels

**iPhone 6.5" Display (iPhone 11 Pro Max, XS Max):**
- [ ] 2 - 10 screenshots
- Size: 1242 x 2688 pixels

**iPhone 5.5" Display (iPhone 8 Plus, 7 Plus):**
- [ ] 2 - 10 screenshots
- Size: 1242 x 2208 pixels

**iPad Pro (6th Gen) 12.9" Display:**
- [ ] 2 - 10 screenshots
- Size: 2048 x 2732 pixels

**Tip**: Screenshots can be the same across devices, just resize them.

**Optional (but recommended):**
- [ ] App Preview Videos
  - 15-30 seconds
  - Show key features
  - MP4 or MOV format

#### 3. Build Your App in Xcode

**Update Version and Build Numbers:**

1. Open Xcode
2. Select your project → General tab
3. Update:
   - **Version**: 1.0.0 (shown to users)
   - **Build**: 1 (internal tracking, increment for each upload)

**Archive Your App:**

```bash
# 1. Clean build folder
Product → Clean Build Folder (Shift + Cmd + K)

# 2. Select target device: "Any iOS Device"

# 3. Create archive
Product → Archive

# 4. Wait for build to complete
# Archive will appear in Organizer window
```

**Important Build Settings:**

In Xcode → Project → Build Settings:
- [ ] Set "iOS Deployment Target" to iOS 12.0 or later
- [ ] Ensure "Release" configuration is selected
- [ ] Enable "Bitcode" if required
- [ ] Code signing: "Automatically manage signing" (easier) or manual certificates

#### 4. App Store Connect Setup

**Create App Record:**

1. Go to: https://appstoreconnect.apple.com
2. Click "My Apps" → (+) → "New App"
3. Fill in:
   - **Platforms**: iOS
   - **Name**: Frat Finance Tracker
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select from dropdown (created in Xcode)
   - **SKU**: FRATFINANCE001
   - **User Access**: Full Access

**Fill Out App Information:**

1. **Pricing and Availability**
   - [ ] Price: Free
   - [ ] Availability: All territories or select specific countries

2. **App Privacy**
   - [ ] Privacy Policy URL: https://yoursite.com/privacy
   - [ ] Privacy Practices:
     - Do you collect data? (Yes - for user accounts)
     - Data types collected:
       - Contact Info (email, name)
       - Financial Info (payment records)
       - User Content (payment notes)
     - How is data used?
       - App Functionality
       - Analytics (if using)
     - Is data linked to user? Yes
     - Is data used for tracking? No (unless using analytics)

3. **App Review Information**
   - [ ] First Name, Last Name
   - [ ] Phone Number
   - [ ] Email Address
   - [ ] Demo Account (REQUIRED):
     - Username: `demo@test.com` (create a test account)
     - Password: `DemoPassword123`
     - Additional info: "Use this VP of Finance account to review all features"
   - [ ] Notes (optional):
     - Explain any special features
     - How to test the app
     - Any known issues

4. **Age Rating**
   - Answer questionnaire
   - Likely rating: 4+ (no restricted content)

5. **App Information**
   - [ ] Name: Frat Finance Tracker
   - [ ] Subtitle: Track fraternity dues & payments
   - [ ] Category:
     - Primary: Finance
     - Secondary: Productivity
   - [ ] Content Rights: Check if you own all rights

#### 5. Upload Build

**Using Xcode:**

1. In Xcode Organizer (after archiving)
2. Select your archive
3. Click "Distribute App"
4. Select "App Store Connect"
5. Select "Upload"
6. Follow prompts:
   - App Store Distribution
   - Automatically manage signing (recommended)
   - Upload
7. Wait for upload to complete (5-30 minutes)
8. Build will appear in App Store Connect after processing

**Verify Upload:**
1. Go to App Store Connect
2. Your App → TestFlight tab
3. Wait for "Processing" to change to "Ready to Submit"
4. Check for any warnings or issues

#### 6. Submit for Review

1. Go to App Store Connect → Your App
2. Version 1.0 → App Store tab
3. Click "Add for Review"
4. Fill out:
   - [ ] Export Compliance (Do you use encryption? Usually "No" for basic apps)
   - [ ] Advertising Identifier (Do you use advertising? Usually "No")
5. Click "Submit for Review"

**Review Timeline:**
- Typically 24-48 hours
- Can be up to 1 week
- You'll receive email updates on status

### Phase 2: Information You Need From Xcode/Apple

**From Xcode:**
- [ ] Bundle Identifier: `com.yourcompany.fratfinancetracker`
- [ ] Team ID: 10-character code (Xcode → Preferences → Accounts)
- [ ] App Version: 1.0.0
- [ ] Build Number: 1
- [ ] Deployment Target: iOS 12.0 (or your minimum version)

**From Apple Developer Portal:**
- [ ] App ID (created automatically or manually)
- [ ] Provisioning Profiles (for distribution)
- [ ] Certificates:
  - iOS Distribution Certificate
  - Push Notification Certificate (if using push notifications)

**From App Store Connect:**
- [ ] Apple ID (numerical ID assigned to your app)
- [ ] App-Specific Password (for CI/CD automation)

---

## Google Play Store Deployment

### Phase 1: Prepare Your App

#### 1. App Information to Collect

**Basic Info:**
- [ ] App Name (50 characters max)
  - Example: "Frat Finance Tracker"
- [ ] Short Description (80 characters max)
  - Example: "Track fraternity dues and payments easily"
- [ ] Full Description (4000 characters max)
  - What the app does
  - Key features
  - How to use it
- [ ] App Category
  - Primary: Finance
- [ ] Tags (up to 5)
  - Example: finance, fraternity, payments, dues, tracker

**Contact Details:**
- [ ] Email Address (visible to users)
- [ ] Phone Number (optional)
- [ ] Website (optional)

**Content Rating:**
- [ ] Complete questionnaire to get rating
- Likely: Everyone or Teen (depending on content)

**Privacy Policy:**
- [ ] Privacy Policy URL (REQUIRED)
  - Example: "https://fratfinancetracker.com/privacy"

#### 2. Visual Assets Required

**App Icon:**
- [ ] 512 x 512 pixels
- 32-bit PNG (with alpha)
- No rounded corners

**Feature Graphic:**
- [ ] 1024 x 500 pixels
- JPEG or 24-bit PNG (no alpha)
- Showcases your app

**Screenshots (At least 2, up to 8 per device type):**

**Phone:**
- [ ] 2-8 screenshots
- Minimum: 320 pixels
- Maximum: 3840 pixels
- Recommended: 1080 x 1920 pixels (for modern phones)

**7-inch Tablet (optional):**
- [ ] 2-8 screenshots
- Recommended: 1200 x 1920 pixels

**10-inch Tablet (optional):**
- [ ] 2-8 screenshots
- Recommended: 1600 x 2560 pixels

**Promo Video (optional):**
- [ ] YouTube video URL
- 30-120 seconds
- Shows app features

#### 3. Build Your App for Release

**Update Version in pubspec.yaml:**

```yaml
version: 1.0.0+1
# Format: version+buildNumber
# 1.0.0 = user-facing version
# 1 = build number (increment for each upload)
```

**Create Keystore (First time only):**

```bash
# Run this command to create a keystore
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# You'll be prompted for:
# - Keystore password (SAVE THIS!)
# - Key password (SAVE THIS!)
# - Your name, organization, city, state, country
```

**CRITICAL: Save this information securely!**
- [ ] Keystore file location: `~/upload-keystore.jks`
- [ ] Keystore password: `_______________`
- [ ] Key alias: `upload`
- [ ] Key password: `_______________`

**Configure Signing:**

Create file: `android/key.properties`
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

**Update android/app/build.gradle:**

```gradle
// Add before android block
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...

    // Add signing config
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            // Enables code shrinking and obfuscation
            minifyEnabled true
            // Enables resource shrinking
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

**Build Release APK/AAB:**

```bash
# Navigate to project root
cd /path/to/frat_finance_tracker

# Build Android App Bundle (recommended)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab

# OR build APK (alternative)
flutter build apk --release --split-per-abi

# Output: build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
#         build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
#         build/app/outputs/flutter-apk/app-x86_64-release.apk
```

**Note**: Google Play requires App Bundle (.aab) for new apps.

#### 4. Google Play Console Setup

**Create Application:**

1. Go to: https://play.google.com/console
2. Click "Create app"
3. Fill in:
   - [ ] App name: Frat Finance Tracker
   - [ ] Default language: English (United States)
   - [ ] App or game: App
   - [ ] Free or paid: Free
4. Agree to declarations
5. Click "Create app"

**Complete Dashboard Tasks:**

**1. App Access:**
- [ ] Select: "All or some functionality is restricted"
- [ ] Provide demo credentials:
  - Username: `demo@test.com`
  - Password: `DemoPassword123`
  - Instructions: "Use this VP of Finance account to test all features"

**2. Ads:**
- [ ] Select: "No, my app does not contain ads"
  - (Unless you're using ads)

**3. Content Rating:**
- [ ] Start questionnaire
- [ ] Answer all questions honestly
- [ ] Submit for rating
- [ ] Wait for rating certificate

**4. Target Audience:**
- [ ] Target age: 18+
- [ ] Appeal to children: No

**5. News Apps:**
- [ ] Select: "No, my app is not a news app"

**6. COVID-19 Contact Tracing:**
- [ ] Select: "No"

**7. Data Safety:**
Fill out what data you collect:
- [ ] Location: No
- [ ] Personal info: Yes
  - Name, Email address
  - Purpose: App functionality, Account management
  - Optional or required: Required
- [ ] Financial info: Yes
  - Payment info (payment records)
  - Purpose: App functionality
  - Optional or required: Required
- [ ] App activity: No (unless you have analytics)
- [ ] Device or other IDs: No

**8. Government Apps:**
- [ ] Select: "No"

**9. Privacy Policy:**
- [ ] Enter URL: https://yoursite.com/privacy

#### 5. Create Release

**Production Release:**

1. Go to: Production → Create new release
2. Upload your AAB file
3. Release name: Auto-filled from version
4. Release notes (What's new):
   ```
   Initial release features:
   • Track fraternity dues and payments
   • Role-based access (Brothers & VP of Finance)
   • Payment history tracking
   • Real-time updates
   • Secure authentication
   ```

**Rollout Percentage:**
- [ ] Start with 20% rollout (staged rollout)
  - Or 100% for immediate full release

**Review Summary:**
- Review all information
- Fix any warnings or errors

**Submit for Review:**
- Click "Start rollout to Production"
- Wait for review (typically 1-7 days)

### Phase 2: Information You Need From Android Studio/Gradle

**From android/app/build.gradle:**
- [ ] Application ID: `com.example.fratfinancetracker`
- [ ] Version Name: `1.0.0`
- [ ] Version Code: `1`
- [ ] Min SDK Version: Usually `21` (Android 5.0)
- [ ] Target SDK Version: `34` (Android 14)

**From Keystore:**
- [ ] SHA-1 Certificate Fingerprint
  ```bash
  keytool -list -v -keystore ~/upload-keystore.jks -alias upload
  ```
- [ ] SHA-256 Certificate Fingerprint

**From Firebase (if using):**
- [ ] Package name (must match application ID)
- [ ] google-services.json file

---

## Post-Deployment

### Monitor Your App

**Apple App Store:**
- [ ] Monitor App Store Connect for:
  - Review status updates
  - Crash reports
  - User reviews and ratings
  - Download statistics

**Google Play Store:**
- [ ] Monitor Play Console for:
  - Review status
  - Crash reports (via Play Console)
  - User reviews and ratings
  - Install statistics
  - Pre-launch reports

### Respond to Reviews

- Set up email notifications for new reviews
- Respond to user feedback within 7 days
- Address bugs and feature requests

### Plan Updates

**Version Numbering:**
- Bug fixes: 1.0.1 (patch)
- New features: 1.1.0 (minor)
- Major changes: 2.0.0 (major)

**Build Numbers:**
- iOS: Increment by 1 for each upload (1, 2, 3, ...)
- Android: Increment versionCode for each upload

---

## Complete Checklist

### Before Submission

- [ ] App tested on multiple devices
- [ ] All features working correctly
- [ ] No crashes or critical bugs
- [ ] Privacy policy created and hosted
- [ ] Support email set up
- [ ] Demo account created for reviewers
- [ ] All required screenshots created
- [ ] App icon finalized (1024x1024 for iOS, 512x512 for Android)
- [ ] App descriptions written
- [ ] Keywords researched and added

### iOS Specific

- [ ] Apple Developer account ($99) paid and active
- [ ] Bundle ID created and matches Xcode
- [ ] Certificates and provisioning profiles configured
- [ ] App archived and uploaded to App Store Connect
- [ ] All App Store Connect fields filled
- [ ] TestFlight build tested
- [ ] Submitted for review

### Android Specific

- [ ] Google Play Developer account ($25) paid and active
- [ ] Keystore created and backed up securely
- [ ] key.properties file created (NOT committed to git)
- [ ] App Bundle (.aab) built successfully
- [ ] All Play Console dashboard tasks completed
- [ ] Content rating received
- [ ] Internal testing completed
- [ ] Production release created and submitted

### Post-Launch

- [ ] Monitor crash reports daily
- [ ] Respond to user reviews
- [ ] Track download metrics
- [ ] Plan first update (bug fixes)
- [ ] Set up app analytics (optional)
- [ ] Create marketing materials
- [ ] Share with target audience (fraternities)

---

## Common Issues & Solutions

### iOS Issues

**Issue**: "Bundle ID already exists"
- Solution: Use a unique bundle ID (e.g., add your name: `com.yourname.fratfinancetracker`)

**Issue**: "Missing compliance"
- Solution: Answer export compliance questions in App Store Connect

**Issue**: "Invalid provisioning profile"
- Solution: Let Xcode automatically manage signing

### Android Issues

**Issue**: "Keystore not found"
- Solution: Check path in key.properties, use absolute path

**Issue**: "Upload failed - version code must be unique"
- Solution: Increment versionCode in build.gradle

**Issue**: "App Bundle not signed"
- Solution: Verify signingConfigs in build.gradle

### Both Platforms

**Issue**: App rejected for missing privacy policy
- Solution: Create and host a privacy policy, add URL

**Issue**: App rejected - demo account doesn't work
- Solution: Test demo account thoroughly before submission

---

## Resources

### Apple
- App Store Connect: https://appstoreconnect.apple.com
- Developer Portal: https://developer.apple.com/account
- Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/

### Google
- Play Console: https://play.google.com/console
- Material Design: https://material.io/design
- Launch Checklist: https://developer.android.com/distribute/best-practices/launch/launch-checklist

### Flutter
- iOS Deployment: https://docs.flutter.dev/deployment/ios
- Android Deployment: https://docs.flutter.dev/deployment/android
- App Bundle: https://flutter.dev/docs/deployment/android#building-the-app-for-release
