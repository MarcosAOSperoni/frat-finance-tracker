# Fraternity Finance Tracker - Technical Architecture

## Tech Stack

### Frontend (Mobile App)
- **Framework:** Flutter 3.24+
- **Language:** Dart 3.5+
- **State Management:** Riverpod 2.x
- **Navigation:** go_router
- **Local Storage:** sqflite + shared_preferences
- **UI Components:** Material Design 3

### Backend
- **BaaS:** Supabase (PostgreSQL + Auth + Real-time + Storage)
- **Authentication:** Supabase Auth (Email/Password)
- **Database:** PostgreSQL with Row Level Security (RLS)

### Notifications
- **Push Notifications:** Firebase Cloud Messaging (FCM)
- **Scheduling:** Supabase Edge Functions (Deno) + pg_cron

### DevOps & Deployment
- **Version Control:** Git + GitHub
- **CI/CD:** GitHub Actions (optional for automated testing)
- **App Deployment:**
  - iOS: App Store Connect (manual submission)
  - Android: Google Play Console (manual submission)

---

## Database Schema

### Tables

#### `users`
```sql
id: uuid (PK, references auth.users)
email: text
full_name: text
role: enum ('brother', 'vp_finance')
phone: text (optional)
created_at: timestamp
updated_at: timestamp
```

#### `payment_schedules`
```sql
id: uuid (PK)
user_id: uuid (FK -> users.id)
amount: decimal
due_date: date
status: enum ('pending', 'paid', 'overdue')
semester: text (e.g., 'Fall 2025', 'Spring 2026')
notes: text (optional)
paid_at: timestamp (nullable)
created_at: timestamp
updated_at: timestamp
```

#### `notification_preferences`
```sql
id: uuid (PK)
user_id: uuid (FK -> users.id)
push_enabled: boolean (default true)
email_enabled: boolean (default true)
reminder_days: int[] (default [7, 3, 1])
created_at: timestamp
updated_at: timestamp
```

### Row Level Security (RLS) Policies

**`users` table:**
- Brothers: Can read only their own row
- VP of Finance: Can read all rows

**`payment_schedules` table:**
- Brothers: Can read only their own payment schedules
- VP of Finance: Can read and write all payment schedules

**`notification_preferences` table:**
- Users: Can read and update only their own preferences

---

## App Architecture

### Folder Structure
```
lib/
├── main.dart
├── app/
│   ├── app.dart                    # Main app widget
│   └── router.dart                 # go_router configuration
├── core/
│   ├── constants/                  # App constants, colors, strings
│   ├── theme/                      # App theme configuration
│   └── utils/                      # Helper functions
├── features/
│   ├── auth/
│   │   ├── data/                   # Supabase auth repository
│   │   ├── domain/                 # User model, auth repository interface
│   │   ├── presentation/           # Login, signup screens
│   │   └── providers/              # Riverpod auth providers
│   ├── dashboard/
│   │   ├── presentation/           # Home screen (different for brother vs VP)
│   │   └── widgets/                # Dashboard widgets
│   ├── payments/
│   │   ├── data/                   # Payment repository
│   │   ├── domain/                 # Payment models
│   │   ├── presentation/           # Payment list, calendar views
│   │   └── providers/              # Payment state providers
│   └── profile/
│       ├── presentation/           # Profile, settings screens
│       └── providers/              # User profile providers
└── shared/
    ├── widgets/                    # Reusable widgets (buttons, cards, etc.)
    └── services/                   # Supabase client, notification service
```

---

## Key Features Implementation

### 1. Authentication & Authorization
```dart
// Supabase Auth
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(supabaseClientProvider));
});

// Check user role on login
Future<UserRole> getUserRole(String userId) async {
  final response = await supabase
    .from('users')
    .select('role')
    .eq('id', userId)
    .single();
  return UserRole.fromString(response['role']);
}
```

### 2. Calendar View
**Package:** `table_calendar` or `flutter_calendar_carousel`

- Display all due dates for the logged-in brother
- VP of Finance: Show all brothers' due dates (color-coded by status)
- Tap on date to see payment details

### 3. Payment Tracking
```dart
// Brother view: See only their payments
Future<List<Payment>> getBrotherPayments(String userId) async {
  return await supabase
    .from('payment_schedules')
    .select()
    .eq('user_id', userId)
    .order('due_date', ascending: true);
}

// VP of Finance: See all payments
Future<List<Payment>> getAllPayments() async {
  return await supabase
    .from('payment_schedules')
    .select('*, users(full_name, email)')
    .order('due_date', ascending: true);
}
```

### 4. Push Notifications

**Setup:**
1. Configure FCM for both iOS and Android
2. Store FCM tokens in Supabase `users` table
3. Create Supabase Edge Function to send notifications

**Edge Function (Deno):**
```typescript
// supabase/functions/send-reminders/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  const supabase = createClient(/* ... */)

  // Get payments due in 7, 3, 1 days
  const today = new Date()
  const reminderDays = [7, 3, 1]

  for (const days of reminderDays) {
    const targetDate = new Date(today)
    targetDate.setDate(today.getDate() + days)

    const { data: payments } = await supabase
      .from('payment_schedules')
      .select('*, users(fcm_token, full_name)')
      .eq('status', 'pending')
      .eq('due_date', targetDate.toISOString().split('T')[0])

    // Send FCM notifications for each payment
    for (const payment of payments) {
      await sendFCMNotification({
        token: payment.users.fcm_token,
        title: `Payment Reminder`,
        body: `Your $${payment.amount} payment is due in ${days} days`,
      })
    }
  }

  return new Response('Reminders sent', { status: 200 })
})
```

**Scheduled with pg_cron:**
```sql
-- Run daily at 9 AM
SELECT cron.schedule(
  'send-payment-reminders',
  '0 9 * * *',
  $$
  SELECT net.http_post(
    url:='https://your-project.supabase.co/functions/v1/send-reminders',
    headers:='{"Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb
  ) AS request_id;
  $$
);
```

### 5. Offline Support
- Use `sqflite` to cache payment data locally
- Sync with Supabase when online
- Show cached data when offline with "offline mode" indicator

---

## Flutter Packages

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Backend
  supabase_flutter: ^2.5.0

  # Navigation
  go_router: ^14.0.0

  # UI Components
  table_calendar: ^3.1.0
  intl: ^0.19.0

  # Local Storage
  sqflite: ^2.3.0
  shared_preferences: ^2.2.0

  # Notifications
  firebase_core: ^3.0.0
  firebase_messaging: ^15.0.0
  flutter_local_notifications: ^17.0.0

  # Utilities
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0

  # Linting
  flutter_lints: ^4.0.0
```

---

## Development Workflow

### Week 1: Setup & Core Features (15-20 hours)
- [ ] Initialize Flutter project
- [ ] Set up Supabase project and configure auth
- [ ] Create database tables and RLS policies
- [ ] Implement authentication (login/signup)
- [ ] Create basic UI theme and navigation
- [ ] Build dashboard screens (brother vs VP of Finance)

### Week 2: Features & Testing (15-20 hours)
- [ ] Implement payment calendar view
- [ ] Build payment list view with filtering
- [ ] Add payment creation/editing (VP of Finance only)
- [ ] Implement mark as paid functionality
- [ ] Set up FCM and local notifications
- [ ] Add offline caching with sqflite
- [ ] Basic testing on emulators

### Week 3: Polish & Client Review (8-12 hours)
- [ ] UI polish and animations
- [ ] Error handling and loading states
- [ ] Client testing and feedback
- [ ] Bug fixes and revisions
- [ ] Performance optimization

### Week 4: Deployment (5-8 hours)
- [ ] Create Supabase Edge Function for reminders
- [ ] Configure pg_cron for scheduled notifications
- [ ] Build production APK and IPA
- [ ] Create App Store screenshots and descriptions
- [ ] Submit to Apple App Store
- [ ] Submit to Google Play Store
- [ ] Wait for approval (1-3 days typically)

---

## App Store Submission Requirements

### Apple App Store
- [ ] App icon (1024x1024)
- [ ] Screenshots (6.5", 5.5" iPhone sizes)
- [ ] App description and keywords
- [ ] Privacy policy URL
- [ ] Support URL or email
- [ ] Age rating (likely 4+)
- [ ] Pricing: Free
- [ ] Build uploaded via Xcode or Application Loader

### Google Play Store
- [ ] App icon (512x512)
- [ ] Feature graphic (1024x500)
- [ ] Screenshots (phone and tablet)
- [ ] Short description (80 chars)
- [ ] Full description (4000 chars)
- [ ] Privacy policy URL
- [ ] Content rating questionnaire
- [ ] Pricing: Free
- [ ] APK/AAB uploaded via Play Console

---

## Security Considerations

1. **Row Level Security (RLS):** All database access controlled at the database level
2. **API Keys:** Store Supabase keys in `.env` files, never commit
3. **Token Storage:** Use `flutter_secure_storage` for sensitive tokens
4. **HTTPS Only:** All API calls over HTTPS
5. **Input Validation:** Validate all user inputs before sending to backend
6. **Password Requirements:** Minimum 8 characters, enforce in Supabase Auth

---

## Cost Breakdown (Monthly)

| Service | Tier | Cost |
|---------|------|------|
| Supabase | Free Tier | $0 (up to 500MB DB, 2GB bandwidth) |
| Firebase (FCM) | Free Tier | $0 (unlimited notifications) |
| **Total** | | **$0/month** |

For 20 brothers, free tiers are more than sufficient. May need to upgrade Supabase to Pro ($25/month) if database grows beyond 500MB or needs more bandwidth.

---

## Testing Strategy

### Manual Testing
- Test all features on both iOS and Android emulators
- Test on at least one physical device (iOS and Android)
- Test offline mode
- Test push notifications
- Test different user roles (brother vs VP of Finance)

### Automated Testing (Optional for MVP)
- Unit tests for business logic
- Widget tests for critical UI components
- Integration tests for auth flow

---

## Post-Launch Maintenance

### Regular Tasks
- Monitor Supabase logs for errors
- Check notification delivery rates
- Update Flutter/packages quarterly
- Re-submit to App Stores when updating app

### Client Support
- Respond to bug reports within 24 hours
- Minor updates included in $100/semester fee
- Major feature requests quoted separately

---

## Next Steps

1. Client approves proposal and sends deposit
2. Gather requirements (brother list, payment amounts, semester dates)
3. Set up development environment
4. Begin Week 1 development
5. Weekly check-ins with client for feedback

---

**Questions or concerns? Let's discuss before starting development.**
