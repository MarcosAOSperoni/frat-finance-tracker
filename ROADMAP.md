# Development Roadmap - Fraternity Finance Tracker

## Project Overview
**Duration:** 4 weeks
**Budget:** $600 development + $124 store fees
**Client:** [Fraternity Name] - 20 brothers

---

## Week 1: Foundation & Setup (15-20 hours)

### Day 1-2: Project Setup (4-5 hours)
- [ ] Create Flutter project: `flutter create frat_finance_tracker`
- [ ] Set up Git repository and initial commit
- [ ] Configure project structure (folders: core, features, shared)
- [ ] Add dependencies to `pubspec.yaml`
- [ ] Set up Supabase project at supabase.com
- [ ] Configure Supabase Auth (enable email auth)
- [ ] Create database schema (users, payment_schedules, notification_preferences)
- [ ] Set up Row Level Security policies

### Day 3-4: Authentication (6-8 hours)
- [ ] Create auth repository with Supabase integration
- [ ] Build login screen UI
- [ ] Build signup screen UI (VP of Finance creates accounts for brothers)
- [ ] Implement Riverpod auth state management
- [ ] Add auth navigation logic (logged in → dashboard, logged out → login)
- [ ] Test auth flow on iOS and Android emulators

### Day 5-7: Dashboard & Navigation (5-7 hours)
- [ ] Set up go_router with protected routes
- [ ] Create Material Design 3 theme
- [ ] Build brother dashboard (shows their payments)
- [ ] Build VP of Finance dashboard (shows all payments overview)
- [ ] Add bottom navigation bar
- [ ] Create profile/settings screen skeleton

**Deliverable:** Working app with login and basic navigation

---

## Week 2: Core Features (15-20 hours)

### Day 8-10: Payment Management (8-10 hours)
- [ ] Create Payment model with freezed/json_serializable
- [ ] Build payment repository (Supabase CRUD operations)
- [ ] Implement payment list view for brothers (their payments only)
- [ ] Implement payment list view for VP of Finance (all payments)
- [ ] Add filtering by status (pending, paid, overdue)
- [ ] Build "Create Payment" form (VP of Finance only)
- [ ] Build "Edit Payment" form (VP of Finance only)
- [ ] Implement "Mark as Paid" functionality
- [ ] Test RLS policies (brother can't see other brothers' data)

### Day 11-12: Calendar View (4-5 hours)
- [ ] Integrate `table_calendar` package
- [ ] Display payments on calendar as markers
- [ ] Color-code by status (red = overdue, yellow = due soon, green = paid)
- [ ] Add tap handler to show payment details
- [ ] Implement month navigation
- [ ] Brother view: Shows only their payments on calendar
- [ ] VP of Finance view: Shows all payments on calendar

### Day 13-14: Notifications Setup (3-5 hours)
- [ ] Configure Firebase project for iOS and Android
- [ ] Add Firebase configuration files to Flutter project
- [ ] Implement FCM token registration on login
- [ ] Store FCM tokens in Supabase users table
- [ ] Build notification preferences screen
- [ ] Test local notifications on device
- [ ] Create Supabase Edge Function for sending reminders

**Deliverable:** Fully functional app with payment tracking and calendar

---

## Week 3: Polish & Client Testing (8-12 hours)

### Day 15-16: UI/UX Polish (4-6 hours)
- [ ] Add loading states (CircularProgressIndicator)
- [ ] Add error handling with user-friendly messages
- [ ] Implement pull-to-refresh on lists
- [ ] Add empty states ("No payments yet")
- [ ] Add smooth page transitions
- [ ] Improve form validation and error messages
- [ ] Add confirmation dialogs for destructive actions
- [ ] Polish calendar UI (better markers, month header)

### Day 17-18: Offline Support (2-3 hours)
- [ ] Set up sqflite local database
- [ ] Cache payment data locally
- [ ] Implement sync logic (fetch from Supabase, store locally)
- [ ] Show cached data when offline
- [ ] Add "Offline Mode" indicator in app bar

### Day 19-21: Client Review & Revisions (2-3 hours)
- [ ] Build APK for Android testing: `flutter build apk`
- [ ] Build iOS TestFlight build
- [ ] Send builds to client for testing
- [ ] Gather feedback and create revision task list
- [ ] Implement revisions
- [ ] Final client approval

**Deliverable:** Production-ready app approved by client

---

## Week 4: Deployment & Launch (5-8 hours)

### Day 22-23: Backend Finalization (2-3 hours)
- [ ] Deploy Supabase Edge Function for reminders
- [ ] Configure pg_cron to run daily at 9 AM
- [ ] Test reminder function manually
- [ ] Set up environment variables for production
- [ ] Verify RLS policies are working correctly
- [ ] Test notification delivery end-to-end

### Day 24-25: App Store Preparation (3-4 hours)
- [ ] Create app icon (1024x1024) using Canva or Figma
- [ ] Take screenshots on iPhone 6.5" and 5.5" simulators
- [ ] Take screenshots on Android phone and tablet
- [ ] Write app description (focus on benefits for fraternities)
- [ ] Create privacy policy (can use privacy policy generator)
- [ ] Set up App Store Connect listing
- [ ] Set up Google Play Console listing

### Day 26-27: Submission (1-2 hours)
- [ ] Build production iOS app: `flutter build ipa`
- [ ] Upload IPA to App Store Connect via Xcode
- [ ] Submit for App Store review
- [ ] Build production Android app: `flutter build appbundle`
- [ ] Upload AAB to Google Play Console
- [ ] Submit for Google Play review
- [ ] Monitor submission status

### Day 28: Launch & Handoff (1 hour)
- [ ] App approved by Apple (typically 1-3 days)
- [ ] App approved by Google (typically 1-2 days)
- [ ] Send app store links to client
- [ ] Create admin account for VP of Finance
- [ ] Brief training call/video for VP of Finance
- [ ] Provide documentation for adding brothers and payments
- [ ] Collect final payment ($300)

**Deliverable:** Live apps on both App Stores

---

## Post-Launch (Ongoing)

### First Week After Launch
- [ ] Monitor crash reports (Firebase Crashlytics - optional)
- [ ] Check Supabase logs for errors
- [ ] Respond to any urgent client issues
- [ ] Verify notifications are being sent correctly

### Ongoing Maintenance ($100/semester)
- [ ] Monthly check-in with client
- [ ] Apply security updates to Flutter/packages
- [ ] Fix any reported bugs
- [ ] Monitor backend costs (should be $0 on free tiers)
- [ ] Respond to support requests within 24 hours

---

## Risk Mitigation

### Potential Issues & Solutions

**Issue:** App Store rejection
**Solution:** Follow Apple's guidelines strictly, have privacy policy, ensure app doesn't crash

**Issue:** Push notifications not working
**Solution:** Test FCM thoroughly on physical devices, not just emulators

**Issue:** Client wants scope changes
**Solution:** Document current scope clearly, quote additional work separately

**Issue:** Running over 4-week timeline
**Solution:** Focus on MVP features first, move "nice-to-haves" to post-launch updates

**Issue:** Supabase RLS is complex
**Solution:** Test RLS policies thoroughly with multiple test accounts

---

## Client Communication Plan

### Weekly Check-ins
- **Friday of Week 1:** Demo auth and basic navigation
- **Friday of Week 2:** Demo full feature set (payments, calendar)
- **Friday of Week 3:** Client testing and revisions
- **Friday of Week 4:** Launch confirmation and handoff

### Communication Channels
- Primary: Text/iMessage for quick updates
- Secondary: Email for formal approvals and documentation
- Emergency: Phone call for critical issues

---

## Success Metrics

**Project Success:**
- ✅ App published on both App Stores within 4 weeks
- ✅ All core features working (calendar, payments, notifications, privacy)
- ✅ Client approves final product
- ✅ Zero critical bugs at launch

**Business Success:**
- ✅ Client pays final invoice on time
- ✅ Client agrees to $100/semester maintenance plan
- ✅ Client provides testimonial for portfolio
- ✅ Client refers another fraternity (bonus!)

---

## Budget Tracking

| Item | Cost | Status |
|------|------|--------|
| Development (Upfront 50%) | $300 | Pending |
| Development (Final 50%) | $300 | Pending |
| Apple Developer Account | $99 | Pending |
| Google Play Store | $25 | Pending |
| **Total** | **$724** | |

**Operating Costs (covered by maintenance fee):**
- Supabase: $0 (free tier sufficient for 20 users)
- Firebase: $0 (free tier unlimited notifications)
- Domain (optional): $12/year

---

## Next Steps

1. ✅ Proposal sent to client
2. ⏳ Wait for client approval and deposit
3. ⏳ Send requirements questionnaire (brother list, payment schedule)
4. ⏳ Begin Week 1 development
5. ⏳ Weekly progress updates

---

**Ready to start building as soon as the deposit clears!**
