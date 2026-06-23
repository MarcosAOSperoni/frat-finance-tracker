Complete Guide: Publishing Your iOS App Using Xcode

  This guide walks you through publishing the Frat Finance Tracker app to the iOS App Store, primarily using Xcode.

  ---
  Prerequisites

  1. Apple Developer Account

  - Cost: $99/year
  - Sign up: https://developer.apple.com/programs
  - Enrollment time: Usually 24-48 hours for approval
  - What you need:
    - Apple ID
    - Credit card for payment
    - D-U-N-S Number (if enrolling as organization)

  2. Mac with Xcode

  - Xcode version: 14.0 or later (get from Mac App Store)
  - macOS: 13.0 (Ventura) or later recommended

  3. Your App Ready

  - ✅ Bundle ID set: com.marcossperoni.fratfinancetracker
  - ✅ Firebase configured
  - ✅ App tested on simulator and real device
  - ⏳ App icon created (1024x1024 PNG)
  - ⏳ Screenshots prepared
  - ⏳ Privacy policy URL ready

  ---
  Step 1: Set Up Signing in Xcode (5 minutes)

  1.1 Add Your Apple ID to Xcode

  1. Open Xcode
  2. Go to: Xcode menu → Settings (or Preferences on older Xcode)
  3. Click Accounts tab
  4. Click + button (bottom left)
  5. Select Apple ID
  6. Sign in with your Apple Developer account credentials
  7. After signing in, you should see your account with "Personal Team" or your organization name

  1.2 Configure Signing

  1. Open your project:
  cd /Users/marcossperoni/development/GitHub/frat-finance-tracker/frat_finance_tracker
  open ios/Runner.xcworkspace
  2. In Xcode:
    - Select "Runner" (blue project icon) in the left sidebar
    - Select "Runner" under TARGETS
    - Click "Signing & Capabilities" tab
  3. Enable automatic signing:
    - ✅ Check "Automatically manage signing"
    - Team: Select your Apple Developer team from dropdown
    - Bundle Identifier: Should show com.marcossperoni.fratfinancetracker
    - Xcode will automatically create:
        - Development certificate
      - Provisioning profiles
  4. Verify no errors:
    - You should see: ✅ "Signing for 'Runner' is enabled"
    - If you see errors, make sure your Apple Developer account is active

  1.3 Add Required Capabilities

  Still in Signing & Capabilities tab:

  1. Click "+ Capability"
  2. Add "Push Notifications"
  3. Add "Background Modes" and check:
    - ✅ Remote notifications

  ---
  Step 2: Prepare App Assets

  2.1 App Icon (REQUIRED)

  What you need: 1024x1024 PNG, no transparency, no rounded corners

  Create the icon:
  - Use https://appicon.co or design in Figma/Photoshop
  - Suggested design: Fraternity letters + dollar sign + navy/gold colors

  Add to Xcode:
  1. In Xcode, navigate to: Runner → Assets.xcassets → AppIcon
  2. Drag your 1024x1024 PNG into the "App Store iOS 1024pt" slot
  3. Xcode will automatically generate all other sizes

  Generate all sizes automatically:

  You can also use Flutter package:
  # Add to pubspec.yaml dev_dependencies:
  flutter pub add flutter_launcher_icons --dev

  Then configure in pubspec.yaml:
  flutter_launcher_icons:
    ios: true
    image_path: "assets/icon/app_icon.png"

  Run: flutter pub run flutter_launcher_icons

  2.2 Screenshots (REQUIRED)

  You need screenshots for different iPhone sizes:

  Required sizes:
  - 6.7" iPhone (1290 x 2796) - iPhone 14 Pro Max, 15 Pro Max
  - 6.5" iPhone (1284 x 2778) - iPhone 13 Pro Max, 12 Pro Max
  - 5.5" iPhone (1242 x 2208) - iPhone 8 Plus (still required!)

  How to take screenshots:

  1. Run app on simulators:
  # List available simulators
  flutter emulators

  # Or from Xcode: Xcode → Open Developer Tool → Simulator
  2. Take screenshots:
    - Run your app on each required simulator size
    - Navigate to interesting screens (dashboard, payment plan, etc.)
    - Press Cmd + S to save screenshot to Desktop
    - Take 3-5 screenshots per device size
  3. What to screenshot:
    - Login screen (optional)
    - Brother dashboard with dues
    - Payment plan view
    - Payment history
    - VP dashboard (if relevant)

  Tip: Use https://www.appstorescreenshot.com/ to add device frames and text overlays

  ---
  Step 3: Update App Version & Build Number

  3.1 Update in pubspec.yaml

  # Edit this file:
  # /Users/marcossperoni/development/GitHub/frat-finance-tracker/frat_finance_tracker/pubspec.yaml

  # Change the version line:
  version: 1.0.0+1

  # Format: MAJOR.MINOR.PATCH+BUILD_NUMBER
  # 1.0.0 = Version shown to users
  # +1 = Build number (must increment for each upload)

  3.2 Verify in Xcode

  In Xcode:
  - Select Runner target → General tab
  - Version: Should show 1.0.0
  - Build: Should show 1

  ---
  Step 4: Create App in App Store Connect (Web - 10 minutes)

  Unfortunately, this MUST be done on the website - Xcode can't do this part.

  4.1 Go to App Store Connect

  1. Visit: https://appstoreconnect.apple.com
  2. Sign in with your Apple Developer account
  3. Click "My Apps"
  4. Click "+" button → "New App"

  4.2 Fill Out App Information

  Platforms: ✅ iOS

  Name: Frat Finance Tracker (or your chosen name)
  - This is the public app name
  - 30 character limit
  - Check availability (must be unique across App Store)

  Primary Language: English (U.S.)

  Bundle ID: Select com.marcossperoni.fratfinancetracker from dropdown
  - If you don't see it, go back to Xcode and make sure you've built the app once

  SKU: fratfinancetracker001
  - Internal identifier (users never see this)
  - Can be anything unique to you

  User Access: Full Access

  Click "Create"

  ---
  Step 5: Build and Archive in Xcode (15 minutes)

  5.1 Clean Build

  cd /Users/marcossperoni/development/GitHub/frat-finance-tracker/frat_finance_tracker
  flutter clean
  flutter pub get

  5.2 Build for Release

  flutter build ios --release

  This creates an optimized iOS build.

  5.3 Archive in Xcode

  1. Open Xcode workspace:
  open ios/Runner.xcworkspace
  2. Select "Any iOS Device" as build target:
    - At the top of Xcode, click the device dropdown (next to Runner)
    - Select "Any iOS Device (arm64)"
    - Don't select a simulator - must be "Any iOS Device"
  3. Create Archive:
    - Menu: Product → Archive
    - Wait for build to complete (2-5 minutes)
    - Xcode will compile your app in release mode
  4. Archives window appears:
    - If it doesn't auto-open: Window → Organizer → Archives tab
    - You should see your app with today's date
    - Version: 1.0.0 (1)

  5.4 Validate the Archive (Recommended)

  Before uploading, validate your archive:

  1. In Archives window, select your archive
  2. Click "Validate App" button
  3. Select your distribution certificate (Xcode handles this automatically)
  4. Click "Validate"
  5. Wait for validation (1-2 minutes)
  6. If successful: ✅ "Validation succeeded"
  7. If errors: Fix them and rebuild

  Common validation errors:
  - Missing compliance info → Will fix in App Store Connect
  - Missing marketing icon → Add 1024x1024 icon
  - Invalid bundle ID → Check Xcode signing settings

  5.5 Upload to App Store Connect

  1. In Archives window, click "Distribute App"
  2. Select "App Store Connect"
  3. Click "Upload"
  4. Keep default settings:
    - ✅ Upload your app's symbols (for crash reports)
    - ✅ Manage Version and Build Number (automatic)
  5. Click "Next"
  6. Review signing certificate (automatic)
  7. Click "Upload"
  8. Wait for upload (5-10 minutes depending on internet speed)
  9. You'll see: ✅ "Upload Successful"

  Note: After upload, it takes 10-30 minutes for the build to appear in App Store Connect and be processed.

  ---
  Step 6: Complete App Store Listing (Web - 30 minutes)

  Go back to https://appstoreconnect.apple.com

  6.1 Add Screenshots

  1. Click your app → iOS App section
  2. Scroll to App Store section
  3. Under Screenshots:
    - Click 6.7" Display
    - Drag your iPhone 15 Pro Max screenshots (min 1, max 10)
    - Click 6.5" Display
    - Drag your iPhone 13 Pro Max screenshots
    - Click 5.5" Display
    - Drag your iPhone 8 Plus screenshots

  6.2 Write App Description

  Promotional Text (170 characters, can be updated anytime):
  Track fraternity dues and payments effortlessly. Create payment plans, record payments, and stay organized with real-time notifications.

  Description (4000 characters max):
  Frat Finance Tracker is the ultimate financial management tool for fraternities. Designed specifically for Greek life organizations, this app streamlines dues collection, payment tracking, and financial transparency between brothers and chapter leadership.

  FEATURES:

  FOR BROTHERS:
  • View all assigned dues and payment deadlines
  • Create flexible payment plans (1-10 installments)
  • Track payment history with detailed records
  • Receive push notifications for upcoming payments
  • Real-time updates on remaining balances
  • Secure authentication and data protection

  FOR VP OF FINANCE:
  • Create and manage dues periods
  • Record payments for all brothers
  • Send invitation codes for new members
  • Monitor chapter-wide payment status
  • Comprehensive financial oversight
  • Export payment reports

  PAYMENT PLANS:
  Break down large dues into manageable payments. Our smart payment scheduler automatically calculates payment amounts and due dates, adjusting dynamically as payments are made.

  SECURITY:
  • Bank-level encryption for all data
  • Secure cloud backup via Supabase
  • Role-based access control
  • Privacy-first design

  NOTIFICATIONS:
  Stay informed with:
  • Payment due date reminders
  • New dues assignments
  • Payment confirmations
  • Real-time balance updates

  Perfect for:
  • Fraternity chapters managing semester dues
  • Treasurers tracking member payments
  • Brothers staying on top of financial obligations
  • Organizations seeking transparent financial management

  Frat Finance Tracker replaces spreadsheets and manual tracking with a modern, mobile-first solution designed specifically for Greek life financial management.

  Keywords (100 characters, comma-separated):
  fraternity,dues,payments,finance,greek life,chapter,treasurer,payment plan,college,university

  Support URL:
  https://github.com/marcossperoni/fratfinancetracker/issues
  (Or create a simple Google Form for support requests)

  Marketing URL: (optional)
  Leave blank for now

  6.3 Privacy Policy (REQUIRED)

  You MUST have a privacy policy URL. Quick options:

  Option 1: GitHub Pages (Free)
  1. Create file: privacy-policy.html
  2. Upload to a new GitHub repo
  3. Enable GitHub Pages
  4. URL: https://yourusername.github.io/privacy-policy

  Option 2: Privacy Policy Generator
  1. Use https://www.privacypolicies.com/privacy-policy-generator/
  2. Fill out form:
    - Data collected: Email, Name, Payment information
    - Third parties: Supabase (hosting), Sentry (error tracking), Firebase (notifications)
    - User rights: Access, deletion, modification
  3. Generate and host anywhere public

  Add to App Store Connect:
  - Privacy Policy URL: [your URL here]

  6.4 App Information

  Subtitle (30 characters):
  Manage Chapter Dues & Payments

  Category:
  - Primary: Finance
  - Secondary: Productivity

  Content Rights:
  - Does your app contain, display, or access third-party content? No

  Age Rating:
  1. Click Edit next to Age Rating
  2. Answer questionnaire:
    - Violence: None
    - Medical/Treatment: None
    - Profanity or Crude Humor: None
    - Sexual Content: None
    - Horror/Fear: None
    - Mature/Suggestive: None
    - Alcohol, Tobacco, or Drugs: None (unless fraternity context requires disclosure)
    - Gambling: None
    - Unrestricted Web Access: No
    - User Generated Content: Yes (brothers can interact)
  3. Result: Likely 4+ rating

  6.5 App Privacy

  Click App Privacy (left sidebar):

  1. Data Collection:
    - Click Get Started
    - Do you collect data from this app? Yes
  2. Data Types:
    - Click Contact Info:
        - ✅ Email Address
      - Purpose: App functionality, Developer communications
      - Linked to user: Yes
      - Used for tracking: No
    - Click Financial Info:
        - ✅ Payment Info (payment amounts, dates)
      - Purpose: App functionality
      - Linked to user: Yes
      - Used for tracking: No
    - Click Identifiers:
        - ✅ User ID
      - Purpose: App functionality
      - Linked to user: Yes
      - Used for tracking: No
  3. Privacy Practices:
    - Data used to track you: No
    - Data linked to you: Yes (email, payment info, user ID)
    - Data not linked to you: None
  4. Save

  6.6 App Review Information

  Contact Information:
  - First Name: Marcos
  - Last Name: Speroni
  - Phone: [Your phone number]
  - Email: [Your email]

  Notes:
  This app is designed for fraternity financial management.

  TEST ACCOUNTS:

  VP of Finance Account:
  Email: [create a test VP account]
  Password: [test password]

  Brother Account:
  Email: [create a test brother account]
  Password: [test password]

  HOW TO TEST:
  1. Log in as VP of Finance
  2. Navigate to Admin Dashboard
  3. Create a dues period
  4. Record a payment for the brother account
  5. Log out and log in as Brother
  6. View dues and create a payment plan

  The app requires a valid invitation code for new signups. Test accounts are pre-created.

  Attachment: (optional)
  Upload a PDF with screenshots and testing instructions if needed

  6.7 Version Information

  Copyright:
  2025 Marcos Speroni

  Version: 1.0.0

  What's New in This Version:
  Initial release of Frat Finance Tracker!

  Features:
  • Track fraternity dues and payments
  • Create flexible payment plans
  • Push notifications for reminders
  • Secure role-based access
  • Real-time payment history
  • Admin dashboard for VP of Finance

  6.8 Build

  1. Scroll to Build section
  2. If your build still shows "Processing" → Wait
  3. Once processed, click the + button
  4. Select your build 1.0.0 (1)
  5. Export Compliance:
    - Does your app use encryption? Yes
    - Is your app exempt from export compliance? Yes (standard HTTPS only)
    - Save

  ---
  Step 7: Submit for Review

  7.1 Final Checklist

  Before submitting, verify:
  - ✅ Screenshots added for all required sizes
  - ✅ App icon (1024x1024) added
  - ✅ Description written
  - ✅ Keywords added
  - ✅ Privacy policy URL added
  - ✅ Privacy details completed
  - ✅ Age rating set
  - ✅ Build selected
  - ✅ Test account credentials provided
  - ✅ Support URL added

  7.2 Submit

  1. Click Add for Review (top right)
  2. Click Submit to App Review
  3. Confirm submission
  4. Status changes to: Waiting for Review

  ---
  Step 8: Review Process (24-48 hours)

  What Happens Next:

  1. In Review (usually within 24 hours)
    - Apple reviewer tests your app
    - Checks functionality, privacy, guidelines compliance
  2. Possible Outcomes:

  2. ✅ Approved (most likely):
    - Status: Pending Developer Release or Ready for Sale
    - You can release manually or it auto-releases

  ⚠️ Metadata Rejected:
    - Issue with description, screenshots, or app info
    - Fix in App Store Connect and resubmit (no new build needed)

  ❌ Binary Rejected:
    - Issue with app functionality or guideline violation
    - Must fix code, increment build number, upload new build
    - Common reasons: Crashes, missing features described in listing, privacy issues

  Common First-Time Rejections:

  - Missing functionality: Description promises features not in app
  - Crashes: App crashes during review
  - Privacy violations: Requesting data without explanation
  - Broken features: Payment plans not working, login issues
  - Missing test account: Reviewer can't log in

  If Rejected:

  1. Read the rejection message carefully
  2. Fix the issues
  3. If code changes needed:
    - Update version: 1.0.0+2 in pubspec.yaml
    - Rebuild and re-upload via Xcode
  4. If metadata only:
    - Fix in App Store Connect
  5. Click Submit for Review again

  ---
  Step 9: After Approval

  Release Options:

  Option 1: Automatic Release (default)
  - App goes live immediately after approval

  Option 2: Manual Release
  - You control when it goes live
  - Good for coordinating launch announcements

  Post-Launch:

  1. Monitor:
    - App Store Connect → Analytics
    - Sentry for crashes/errors
    - User reviews
  2. Respond to Reviews:
    - Reply to user feedback
    - Fix bugs in updates
  3. Updates:
    - Fix bugs or add features
    - Increment build number: 1.0.0+2, 1.0.0+3, etc.
    - For feature updates: 1.1.0+1
    - Repeat archive → upload → submit process

  ---
  Quick Command Reference

  # Project directory
  cd /Users/marcossperoni/development/GitHub/frat-finance-tracker/frat_finance_tracker

  # Clean and prepare
  flutter clean
  flutter pub get

  # Build for release
  flutter build ios --release

  # Open Xcode (for archiving)
  open ios/Runner.xcworkspace

  # After opening Xcode:
  # 1. Select "Any iOS Device" as target
  # 2. Product → Archive
  # 3. Distribute → App Store Connect → Upload

  ---
  Troubleshooting

  "No accounts with App Store Connect access"

  - Go to Xcode → Settings → Accounts
  - Remove and re-add your Apple ID
  - Make sure your Developer Program enrollment is active

  "Failed to create provisioning profile"

  - Check bundle ID matches in Xcode and App Store Connect
  - Verify your Apple Developer account is paid and active
  - Try unchecking and rechecking "Automatically manage signing"

  "Archive option is greyed out"

  - Make sure you selected "Any iOS Device" not a simulator
  - Clean build: Product → Clean Build Folder
  - Close and reopen Xcode

  "Upload failed" / "Invalid archive"

  - Check version number is incremented
  - Verify app icon is 1024x1024 PNG
  - Make sure you have valid signing certificate

  Build not appearing in App Store Connect

  - Wait 10-30 minutes for processing
  - Check email for processing errors
  - Verify bundle ID matches

  ---
  Timeline Summary

  - Xcode setup: 5 minutes
  - Prepare assets: 1-2 hours (creating icon, screenshots)
  - App Store Connect setup: 30 minutes
  - Build & upload: 15 minutes
  - Complete listing: 30 minutes
  - Review wait time: 24-48 hours
  - Total: ~2-3 hours of work + 1-2 days waiting

  ---
  Next Steps

  1. Enroll in Apple Developer Program (if not done)
  2. Create app icon (1024x1024 PNG)
  3. Take screenshots on required device sizes
  4. Write/host privacy policy
  5. Follow this guide starting at Step 1

  Good luck with your submission! 🚀