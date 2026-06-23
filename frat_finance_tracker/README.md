# Frat Finance Tracker

A Flutter mobile app for tracking fraternity dues and payments.

## Features
- Brother invitation system
- Self-registration for brothers
- Payment tracking with payment plans
- Calendar view of due dates
- Push notifications
- VP of Finance admin panel

## Tech Stack
- Flutter 3.24+
- Supabase (Backend)
- Riverpod (State Management)
- Go Router (Navigation)

## Setup

### Prerequisites
- Flutter 3.24 or higher
- Xcode (for iOS)
- Android Studio (for Android)
- Supabase account

### Installation

1. Clone the repository
```bash
git clone [repo-url]
cd frat_finance_tracker
```

2. Install dependencies
```bash
flutter pub get
```

3. Set up environment variables
Create `.env` file with:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

4. Run the app
```bash
flutter run
```

## Project Structure
```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── router.dart
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── invitations/
│   ├── payments/
│   └── profile/
└── shared/
    ├── widgets/
    └── services/
```

## Development Timeline
- Week 1: Auth, invitations, navigation
- Week 2: Payment tracking, calendar
- Week 3: Notifications, polish
- Week 4: App Store submission

## Client
- Andrés (VP of Finance)
- 20 brothers
- Payment plan: 4 × $150
