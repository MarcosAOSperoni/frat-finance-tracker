# Quick Start: Error Handling & Monitoring

## 🚀 3-Minute Setup

### 1. Add Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  connectivity_plus: ^5.0.2
  sentry_flutter: ^7.14.0
```

Run:
```bash
flutter pub get
```

### 2. Get Sentry DSN (Free)

1. Visit [https://sentry.io/signup/](https://sentry.io/signup/)
2. Create account → New Project → Flutter
3. Copy your DSN (looks like: `https://abc123@o123.ingest.sentry.io/456`)

### 3. Add to .env

```env
SENTRY_DSN=your-sentry-dsn-here
```

### 4. Update main.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frat_finance_tracker/app/app.dart';
import 'package:frat_finance_tracker/shared/services/supabase_service.dart';
import 'package:frat_finance_tracker/shared/services/error_monitoring_service.dart';
import 'package:frat_finance_tracker/shared/widgets/global_error_handler.dart';
import 'package:frat_finance_tracker/shared/utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  final sentryDsn = dotenv.env['SENTRY_DSN'] ?? '';

  await ErrorMonitoringService.runAppWithErrorMonitoring(
    sentryDsn: sentryDsn,
    environment: dotenv.env['ENV'],
    appRunner: () async {
      ErrorWidget.builder = GlobalErrorHandler.createErrorWidget;

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        ErrorMonitoringService.captureException(details.exception, stackTrace: details.stack);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        ErrorMonitoringService.captureException(error, stackTrace: stack);
        return true;
      };

      await SupabaseService.initialize();

      runApp(
        const ProviderScope(
          child: GlobalErrorHandler(child: App()),
        ),
      );
    },
  );
}
```

### 5. Done! 🎉

Now you have:
- ✅ Loading screens
- ✅ Network error detection
- ✅ Error screens
- ✅ Production error logging
- ✅ Email notifications on errors

---

## 📱 Using in Your Code

### Show Loading

```dart
// Full screen
return LoadingScreen(message: 'Loading...');

// Inline
return InlineLoading(message: 'Processing...');
```

### Handle Async Data

```dart
final dataAsync = ref.watch(dataProvider);

return dataAsync.when(
  data: (data) => YourWidget(data: data),
  loading: () => InlineLoading(),
  error: (e, _) => InlineError(
    message: 'Failed to load',
    onRetry: () => ref.invalidate(dataProvider),
  ),
);
```

### Check Network Before Action

```dart
final isConnected = await ref.read(connectivityServiceProvider).isConnected();
if (!isConnected) {
  // Show error
  return;
}
// Proceed...
```

### Log Errors

```dart
try {
  await someOperation();
} catch (e, stack) {
  ErrorMonitoringService.captureException(
    e,
    stackTrace: stack,
    hint: 'Operation failed',
    extra: {'context': 'details'},
  );
}
```

---

## 🧪 Testing

**Test Network Error:**
1. Turn off WiFi/data
2. Open app → See network error screen
3. Turn on WiFi → Tap "Try Again"

**Test Error Logging:**
1. Build release: `flutter run --release`
2. Trigger an error
3. Check Sentry dashboard in 1 minute

---

## 📊 Monitor in Production

**Sentry Dashboard:** https://sentry.io

You'll get:
- 📧 Email on new errors
- 📈 Error trends
- 🔍 Stack traces
- 👥 Affected users
- 📝 Breadcrumbs (what user did before error)

---

## 💰 Cost

**Free tier:** 5,000 errors/month (plenty for MVP!)

---

For full details, see [ERROR_MONITORING_SETUP.md](ERROR_MONITORING_SETUP.md)
