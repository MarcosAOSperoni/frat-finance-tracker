# Error Monitoring & Handling Setup Guide

This guide explains how to set up error monitoring, loading states, and network error handling in the Frat Finance Tracker app.

---

## Table of Contents

1. [Overview](#overview)
2. [Dependencies Required](#dependencies-required)
3. [Sentry Setup](#sentry-setup)
4. [Integration Steps](#integration-steps)
5. [Testing](#testing)
6. [Usage Examples](#usage-examples)

---

## Overview

The app now includes:

✅ **Loading Screens** - Full-screen and inline loading indicators
✅ **Network Error Detection** - Automatic detection when device loses internet
✅ **Error Screens** - User-friendly error displays
✅ **Production Error Logging** - Automatic error reporting with Sentry
✅ **Global Error Handling** - Catches all unhandled exceptions

---

## Dependencies Required

Add these to `pubspec.yaml`:

```yaml
dependencies:
  # Existing dependencies...
  connectivity_plus: ^5.0.2      # Network connectivity detection
  sentry_flutter: ^7.14.0        # Error monitoring and crash reporting

dev_dependencies:
  # Existing dependencies...
```

Run:
```bash
flutter pub get
```

---

## Sentry Setup

### Step 1: Create Sentry Account (Free)

1. Go to [https://sentry.io/signup/](https://sentry.io/signup/)
2. Sign up for a free account
3. Create a new project:
   - Platform: **Flutter**
   - Project name: **Frat Finance Tracker**

### Step 2: Get Your DSN

After creating the project, you'll see your **DSN** (Data Source Name). It looks like:

```
https://1234567890abcdef1234567890abcdef@o123456.ingest.sentry.io/1234567
```

**IMPORTANT:** Keep this DSN secret! Do not commit it to git.

### Step 3: Add DSN to Environment Variables

Add to your `.env` file:

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=sb_publishable_xxxxx
SENTRY_DSN=https://your-sentry-dsn-here
ENV=development
```

**Make sure `.env` is in your `.gitignore`!**

### Step 4: Configure Sentry Settings (Optional)

In Sentry dashboard:

1. **Alerts** → Create alert rules:
   - Email notification on new errors
   - Slack integration (optional)
   - Discord webhook (optional)

2. **Settings** → **Projects** → **Frat Finance Tracker**:
   - Enable "Auto Session Tracking"
   - Set "Release Health" options
   - Configure data scrubbing rules

---

## Integration Steps

### Step 1: Update main.dart

Replace your current `main.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frat_finance_tracker/app/app.dart';
import 'package:frat_finance_tracker/shared/services/supabase_service.dart';
import 'package:frat_finance_tracker/shared/services/error_monitoring_service.dart';
import 'package:frat_finance_tracker/shared/widgets/global_error_handler.dart';
import 'package:frat_finance_tracker/shared/widgets/loading_screen.dart';
import 'package:frat_finance_tracker/shared/utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Get Sentry DSN from environment
  final sentryDsn = dotenv.env['SENTRY_DSN'] ?? '';

  // Initialize error monitoring (wraps entire app)
  await ErrorMonitoringService.runAppWithErrorMonitoring(
    sentryDsn: sentryDsn,
    environment: dotenv.env['ENV'],
    appRunner: () async {
      // Set custom error widget for Flutter framework errors
      ErrorWidget.builder = GlobalErrorHandler.createErrorWidget;

      // Catch all Flutter framework errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        ErrorMonitoringService.captureException(
          details.exception,
          stackTrace: details.stack,
          hint: 'Flutter error',
        );
      };

      // Catch all async errors
      PlatformDispatcher.instance.onError = (error, stack) {
        ErrorMonitoringService.captureException(
          error,
          stackTrace: stack,
          hint: 'Async error',
        );
        return true;
      };

      // Initialize Supabase
      try {
        await SupabaseService.initialize();
        AppLogger.info('Supabase initialized successfully');
      } catch (e, stackTrace) {
        AppLogger.error('Failed to initialize Supabase', error: e, stackTrace: stackTrace);
        ErrorMonitoringService.captureException(
          e,
          stackTrace: stackTrace,
          hint: 'Supabase initialization failed',
        );
      }

      // Run the app
      runApp(
        const ProviderScope(
          child: GlobalErrorHandler(
            child: App(),
          ),
        ),
      );
    },
  );
}
```

### Step 2: Update App Widget (app/app.dart)

Add network connectivity monitoring:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frat_finance_tracker/app/router.dart';
import 'package:frat_finance_tracker/core/theme/app_theme.dart';
import 'package:frat_finance_tracker/shared/widgets/network_error_screen.dart';
import 'package:frat_finance_tracker/shared/services/connectivity_service.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final connectivityStatus = ref.watch(connectivityStatusProvider);

    return MaterialApp.router(
      title: 'Frat Finance Tracker',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Show network error screen when offline
        return connectivityStatus.when(
          data: (isConnected) {
            if (!isConnected) {
              return NetworkErrorScreen(
                onRetry: () {
                  // Refresh connectivity status
                  ref.invalidate(connectivityStatusProvider);
                },
              );
            }
            return child ?? const SizedBox.shrink();
          },
          loading: () => child ?? const SizedBox.shrink(),
          error: (_, __) => child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
```

---

## Testing

### Test Loading States

```dart
// In any widget
import 'package:frat_finance_tracker/shared/widgets/loading_screen.dart';

// Full screen loading
return LoadingScreen(message: 'Loading your data...');

// Inline loading
return InlineLoading(message: 'Processing...', size: 40);
```

### Test Network Error

1. Turn off WiFi and cellular data on your device
2. Open the app
3. Should see the network error screen with troubleshooting tips
4. Turn WiFi back on and tap "Try Again"

### Test General Errors

```dart
import 'package:frat_finance_tracker/shared/widgets/error_screen.dart';

// Show error screen
return ErrorScreen(
  title: 'Payment Failed',
  message: 'Could not process your payment. Please try again.',
  errorCode: 'PAYMENT_001',
  onRetry: () {
    // Retry logic
  },
  onGoHome: () {
    context.go('/dashboard');
  },
);
```

### Test Error Monitoring

Manually trigger an error to test Sentry:

```dart
import 'package:frat_finance_tracker/shared/services/error_monitoring_service.dart';

// Trigger test error
ElevatedButton(
  onPressed: () {
    ErrorMonitoringService.captureException(
      Exception('Test error from app'),
      hint: 'Testing Sentry integration',
      extra: {
        'userId': 'test-user-123',
        'screen': 'dashboard',
      },
    );
  },
  child: Text('Test Error Reporting'),
)
```

Check Sentry dashboard in ~1 minute to see the error appear.

---

## Usage Examples

### Example 1: Loading State in Repository

```dart
// In any ConsumerWidget
final duesAsync = ref.watch(brotherDuesProvider(userId));

return duesAsync.when(
  data: (dues) => DuesList(dues: dues),
  loading: () => InlineLoading(message: 'Loading dues...'),
  error: (error, _) => InlineError(
    message: 'Failed to load dues',
    onRetry: () {
      ref.invalidate(brotherDuesProvider(userId));
    },
  ),
);
```

### Example 2: Network Error Handling

```dart
import 'package:frat_finance_tracker/shared/services/connectivity_service.dart';

class PaymentScreen extends ConsumerWidget {
  Future<void> _recordPayment(WidgetRef ref) async {
    // Check connectivity before making network request
    final isConnected = await ref.read(connectivityServiceProvider).isConnected();

    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No internet connection. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Proceed with payment...
  }
}
```

### Example 3: Error Monitoring with Context

```dart
try {
  await repository.recordPayment(
    brotherDuesId: duesId,
    amount: amount,
    // ...
  );
} catch (e, stackTrace) {
  // Log error with context
  ErrorMonitoringService.captureException(
    e,
    stackTrace: stackTrace,
    hint: 'Failed to record payment',
    extra: {
      'duesId': duesId,
      'amount': amount.toString(),
      'userId': currentUser.id,
    },
  );

  // Show user-friendly error
  showDialog(
    context: context,
    builder: (context) => ErrorScreen(
      title: 'Payment Failed',
      message: 'Could not record the payment. Please try again.',
      onRetry: () {
        Navigator.pop(context);
        _recordPayment(); // Retry
      },
    ),
  );
}
```

### Example 4: Set User Context (for better error tracking)

```dart
// After successful login
await ErrorMonitoringService.setUserContext(
  userId: user.id,
  role: user.role.value,
);

// On logout
await ErrorMonitoringService.clearUserContext();
```

### Example 5: Add Breadcrumbs for Debugging

```dart
import 'package:frat_finance_tracker/shared/services/error_monitoring_service.dart';

// Add breadcrumbs to track user actions
void _onCreateDues() {
  ErrorMonitoringService.addBreadcrumb(
    message: 'User started creating dues period',
    category: 'user_action',
    data: {
      'screen': 'vp_dashboard',
      'action': 'create_dues',
    },
  );

  // Continue with dues creation...
}
```

---

## Monitoring Errors in Production

### Sentry Dashboard

After deploying to production, monitor errors at:

**https://sentry.io/organizations/your-org/projects/frat-finance-tracker/**

You'll see:
- ✅ Error frequency and trends
- ✅ Affected users count
- ✅ Stack traces with line numbers
- ✅ Device and OS information
- ✅ Breadcrumbs (user actions before error)
- ✅ Custom context (userId, screen, etc.)

### Email Notifications

You'll receive emails for:
- 🔴 New errors (first occurrence)
- ⚠️  Error spikes (sudden increase)
- 📊 Weekly/daily digest

### Slack/Discord Integration (Optional)

Set up in Sentry:
1. Settings → Integrations
2. Connect Slack or Discord
3. Configure alert rules
4. Get instant notifications in your channel

---

## Privacy & Data Scrubbing

The error monitoring service automatically:

✅ **Removes PII** - Email addresses replaced with `[EMAIL]`
✅ **Removes UUIDs** - User IDs replaced with `[ID]`
✅ **Sanitizes errors** - Sensitive data stripped before sending
✅ **Debug-only mode** - Sentry disabled in development
✅ **User consent** - Only sends data in release builds

---

## Performance Impact

- **App size increase:** ~300KB (Sentry SDK)
- **Network usage:** ~5KB per error report
- **Battery impact:** Negligible
- **Startup time:** +10-50ms (one-time initialization)

---

## Cost

**Sentry Free Tier:**
- 5,000 errors/month
- 30-day retention
- Email support
- **Perfect for MVP!**

When you exceed:
- Upgrade to Team plan ($26/month)
- Or Business plan ($80/month)

---

## Troubleshooting

### Errors not appearing in Sentry?

1. Check SENTRY_DSN is correct in `.env`
2. Verify you're in release mode: `flutter run --release`
3. Check Sentry dashboard "Project Settings" → "Client Keys"
4. Enable debug logging:
   ```dart
   options.debug = true; // In ErrorMonitoringService.initialize()
   ```

### Network error screen always showing?

1. Check device WiFi/cellular is ON
2. Test connectivity: `flutter run` and check logs
3. Verify `connectivity_plus` is added to pubspec.yaml
4. Try restarting the app

### Loading screen stuck?

1. Check if there's an error in console
2. Verify async operation is completing
3. Add timeout to async calls:
   ```dart
   final result = await operation().timeout(Duration(seconds: 30));
   ```

---

## Next Steps

1. ✅ Add dependencies to `pubspec.yaml`
2. ✅ Create Sentry account and get DSN
3. ✅ Add SENTRY_DSN to `.env`
4. ✅ Update `main.dart` with error monitoring
5. ✅ Test in release mode
6. ✅ Deploy and monitor!

---

## Support

Need help? Contact:
- **Sentry Support:** https://sentry.io/support/
- **Connectivity Issues:** Check `connectivity_plus` docs
- **App Issues:** Review logs with `AppLogger.debug()`
