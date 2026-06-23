# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Frat Finance Tracker is a Flutter mobile application for tracking fraternity dues and payments. The app supports role-based access for brothers and the VP of Finance, with features including manual dues creation with per-brother payment schedules, payment tracking, payment plans, and payment history.

**Current Version:** 1.3.0

## Tech Stack

- **Framework:** Flutter 3.24+ with Dart 3.5+
- **State Management:** Riverpod 2.x
- **Backend:** Supabase (PostgreSQL + Auth + Real-time)
- **Navigation:** go_router
- **Local Storage:** sqflite + shared_preferences
- **UI:** Material Design 3

## Commands

### Development
```bash
# Run the app
flutter run

# Run on specific device
flutter run -d chrome          # Web
flutter run -d <device_id>     # iOS/Android simulator

# Hot reload (while app is running)
# Press 'r' in terminal

# Clean build
flutter clean && flutter pub get && flutter run

# Get dependencies
flutter pub get

# Generate code (if using build_runner)
flutter pub run build_runner build --delete-conflicting-outputs
```

### iOS Development
```bash
# Install iOS dependencies
cd ios && pod install && cd ..

# List available simulators
flutter emulators

# Open iOS simulator
open -a Simulator
```

### Database
```bash
# Initial SQL setup (tables, triggers, base RLS policies)
# File: supabase_setup.sql

# Migration for dues creation, payment plans, and updated RLS policies
# File: migration_dues_creation_update.sql
# Safe to re-run (uses DROP POLICY IF EXISTS before CREATE POLICY)
```

## Architecture

### Folder Structure
```
lib/
├── main.dart                    # App entry point, initializes Supabase
├── app/
│   ├── app.dart                # Main app widget
│   └── router.dart             # go_router configuration with auth guards
├── core/
│   ├── constants/              # App constants
│   ├── theme/
│   │   └── app_theme.dart      # Material Design theme (navy & gold colors)
│   └── utils/                  # Helper functions
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart        # Supabase auth logic
│   │   ├── domain/
│   │   │   └── app_user.dart               # User model with roles
│   │   ├── presentation/
│   │   │   ├── login_screen.dart           # Email/password login
│   │   │   └── signup_screen.dart          # Invitation-based signup
│   │   └── providers/
│   │       └── auth_provider.dart          # Auth state management
│   ├── dashboard/
│   │   ├── presentation/
│   │   │   ├── brother_dashboard.dart      # Brother view (uses DuesDetailView, isAdmin: false)
│   │   │   ├── brother_management_screen.dart # Manage brother active/inactive status
│   │   │   └── vp_dashboard.dart           # VP admin: overview, brother detail, create dues, delete dues
│   │   └── widgets/
│   │       └── dues_detail_view.dart       # Shared dues detail UI (summary header, grouped payments, admin actions)
│   ├── invitations/
│   │   ├── data/                           # Invitation repository
│   │   ├── domain/                         # Invitation models
│   │   └── providers/                      # Invitation state
│   ├── payments/
│   │   ├── data/
│   │   │   └── payments_repository.dart    # Payment CRUD operations
│   │   ├── domain/
│   │   │   ├── brother_dues.dart           # Dues & Payment models
│   │   │   └── payment_plan.dart           # PaymentPlan & ScheduledPayment models
│   │   └── providers/
│   │       └── payments_provider.dart      # Payment state management
│   └── profile/
│       ├── presentation/                   # Profile/settings screens
│       └── providers/                      # User profile state
└── shared/
    ├── services/
    │   └── supabase_service.dart           # Supabase client singleton
    └── widgets/                            # Reusable UI components
```

### Key Architectural Patterns

**State Management:**
- Uses Riverpod for dependency injection and state management
- Providers are defined in `providers/` folders within each feature
- Auth state flows from `authStateProvider` to control navigation

**Navigation:**
- `go_router` with auth-based redirects
- Logged out → `/login`
- Brother → `/dashboard`
- VP of Finance → `/vp-dashboard`

**Data Flow:**
1. UI widgets (`ConsumerWidget`) watch providers via `ref.watch()`
2. Providers fetch data from repositories
3. Repositories interact with Supabase
4. Supabase enforces Row Level Security (RLS) policies

**Shared Widgets:**
- `DuesDetailView` (`widgets/dues_detail_view.dart`) is the unified dues display used by both brother and VP screens
  - Renders: summary header card (avatar, name, progress bar, stats), payment cards grouped by dues period with colored left borders
  - `isAdmin: true` (VP) shows Record Payment button + Delete icon on unpaid cards
  - `isAdmin: false` (brother) hides all action buttons
  - `onActionCompleted` callback lets the parent handle provider invalidation and navigation after mutations
  - `BrotherDetailScreen` in `vp_dashboard.dart` passes raw maps parsed to `List<BrotherDues>`
  - `BrotherDashboard` in `brother_dashboard.dart` uses a helper widget `_DuesWithPlans` to collect per-dues payment plans before passing to `DuesDetailView`

## Database Schema

### Key Tables

**users** - User profiles with roles
- `role`: 'brother' | 'vp_finance'
- `brother_status`: 'active' | 'inactive' (simplified from previous 4 statuses)
- `profile_completed`: tracks if brother finished signup

**invitations** - Invitation codes for new brothers
- `invitation_code`: unique code sent to brothers
- `status`: 'pending' | 'accepted' | 'expired'
- `expires_at`: 7 days from creation

**dues_periods** - Semester dues definitions
- `name`: e.g., "Spring 2025 Dues"
- `total_amount`: default amount per brother
- `start_date`: when the dues period begins
- `due_date`: when payment is due

**brother_dues** - Individual brother dues assignments
- `total_amount`: can differ from default (scholarships, etc.)
- `amount_paid`: auto-calculated from payments table
- `status`: 'pending' | 'partial' | 'paid' | 'overdue'

**payment_plans** - Payment schedule for a brother's dues
- `brother_dues_id`: links to specific brother_dues
- `total_payments`: number of scheduled payments (1-10)

**scheduled_payments** - Individual scheduled payment entries
- `payment_plan_id`: links to payment_plans
- `payment_number`: sequence number (1, 2, 3...)
- `scheduled_amount`: amount due for this payment
- `scheduled_date`: evenly spaced between start and due date
- `status`: 'pending' | 'paid'

**payments** - Individual payment transactions
- `amount`: payment amount
- `payment_date`: when payment was made
- `payment_method`: Venmo, Cash, etc. (optional)

### Row Level Security (RLS)

**Brothers can:**
- Read only their own user profile
- Read only their own dues, payments, payment plans, and scheduled payments
- Update their own notification preferences

**VP of Finance can:**
- Read all users, dues, payments, payment plans, and scheduled payments
- Create invitations, dues periods, brother_dues, payment plans, and scheduled payments
- Record payments for any brother
- Update any brother's dues and scheduled payments
- Delete brother dues (cascades to payment plans, scheduled payments, and payments)

## Environment Configuration

**.env file** (not committed to git):
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=sb_publishable_xxxxx
ENV=development
```

## Common Development Tasks

### Adding a New Feature

1. Create feature folder under `lib/features/`
2. Add domain models in `domain/`
3. Create repository in `data/`
4. Set up providers in `providers/`
5. Build UI in `presentation/`

### Testing Authentication Flow

1. Ensure Supabase project is set up with `supabase_setup.sql` and `migration_dues_creation_update.sql`
2. Create a VP of Finance user manually in Supabase (or use `set_vp_finance.sql`)
3. VP creates brothers via "Add User" on VP dashboard
4. VP creates dues via "Create Dues" and selects brothers + payment counts
5. Both roles can log in and see role-specific dashboards with scheduled payments

### Debugging Supabase Issues

- Check Supabase logs: Dashboard → Logs → Postgres Logs
- Verify RLS policies: Dashboard → Authentication → Policies
- Test queries: Dashboard → SQL Editor
- Check auth state: `ref.watch(authStateProvider)` in Flutter

## Important Notes

- **First user must be manually set as VP of Finance** in Supabase users table: `UPDATE users SET role = 'vp_finance' WHERE email = 'vp@example.com';` (or use `set_vp_finance.sql`)
- Payment amounts are stored as `DECIMAL(10, 2)` in database
- Database triggers auto-update `brother_dues.amount_paid` when payments are recorded
- All dates are stored in ISO 8601 format
- Authentication uses PKCE flow for security
- Dues creation: VP manually selects active brothers and sets per-brother payment count (1-10). Payments are evenly spaced between start date and due date.
- Brother statuses simplified to active/inactive only (legacy statuses mapped to inactive)
- Deleting a brother's dues removes all associated payment plans, scheduled payments, and recorded payments

## Client Information

- **Client:** Andrés (VP of Finance)
- **Fraternity Size:** 20 brothers
- **Pricing:** $600 development + $70/semester maintenance
- **Timeline:** 4-week MVP development
- **Payment Plan:** 4 × $150 installments

## Next Features (Post-MVP)

- Push notifications for payment reminders
- Calendar view of due dates
- SMS reminders (in addition to email)
- Payment integration (Stripe/PayPal)
- Analytics dashboard for VP
- Export to CSV/Excel
