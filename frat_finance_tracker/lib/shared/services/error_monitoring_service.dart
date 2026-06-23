import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:frat_finance_tracker/shared/utils/app_logger.dart';

/// Service for monitoring and reporting errors in production
class ErrorMonitoringService {
  static bool _isInitialized = false;

  /// Initialize Sentry for error monitoring
  /// Call this before runApp() in main.dart
  static Future<void> initialize({
    required String sentryDsn,
    String? environment,
  }) async {
    if (_isInitialized) {
      AppLogger.warning('Error monitoring already initialized');
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = environment ?? (kReleaseMode ? 'production' : 'development');

        // Set sample rates
        options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0; // 10% in production, 100% in dev

        // Enable breadcrumbs for better debugging
        options.enableAutoSessionTracking = true;
        options.attachThreads = true;
        options.attachStacktrace = true;

        // Filter out sensitive data
        options.beforeSend = (event, {hint}) {
          // Remove any potential PII from error messages
          event = _sanitizeEvent(event);
          return event;
        };

        // Don't send errors in debug mode
        if (kDebugMode) {
          options.dsn = ''; // Disable Sentry in debug mode
        }
      },
    );

    _isInitialized = true;
    AppLogger.info('Error monitoring initialized');
  }

  /// Sanitize event to remove PII before sending to Sentry
  static SentryEvent _sanitizeEvent(SentryEvent event) {
    // Remove email addresses from exception messages
    if (event.message != null) {
      final sanitizedMessage = event.message?.formatted?.replaceAll(
        RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
        '[EMAIL]',
      );
      event = event.copyWith(
        message: SentryMessage(sanitizedMessage ?? event.message!.formatted),
      );
    }

    // Remove UUIDs
    if (event.exceptions != null) {
      final sanitizedExceptions = event.exceptions?.map((exception) {
        final value = exception.value?.replaceAll(
          RegExp(r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b'),
          '[ID]',
        );
        return exception.copyWith(value: value);
      }).toList();

      event = event.copyWith(exceptions: sanitizedExceptions);
    }

    return event;
  }

  /// Capture an exception and send to Sentry
  static Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? hint,
    Map<String, dynamic>? extra,
  }) async {
    if (!_isInitialized) {
      AppLogger.error('Error monitoring not initialized', error: exception);
      return;
    }

    // Log locally first
    AppLogger.error('Exception captured: $hint', error: exception, stackTrace: stackTrace as StackTrace?);

    // Send to Sentry (only in production)
    if (kReleaseMode) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        hint: hint != null ? Hint.withMap({'hint': hint}) : null,
        withScope: (scope) {
          if (extra != null) {
            extra.forEach((key, value) {
              scope.setExtra(key, value);
            });
          }
        },
      );
    }
  }

  /// Capture a message and send to Sentry
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extra,
  }) async {
    if (!_isInitialized) {
      AppLogger.info('Message: $message');
      return;
    }

    // Log locally
    AppLogger.info(message);

    // Send to Sentry (only in production)
    if (kReleaseMode) {
      await Sentry.captureMessage(
        message,
        level: level,
        withScope: (scope) {
          if (extra != null) {
            extra.forEach((key, value) {
              scope.setExtra(key, value);
            });
          }
        },
      );
    }
  }

  /// Add breadcrumb for debugging context
  static void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) {
    if (!_isInitialized) return;

    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        data: data,
        level: level,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Set user context (avoid PII - use only user ID)
  static Future<void> setUserContext({
    required String userId,
    String? role,
  }) async {
    if (!_isInitialized) return;

    await Sentry.configureScope((scope) {
      scope.setUser(
        SentryUser(
          id: userId,
          data: {
            'role': role,
          },
        ),
      );
    });
  }

  /// Clear user context (call on logout)
  static Future<void> clearUserContext() async {
    if (!_isInitialized) return;

    await Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// Wrap app initialization with error monitoring
  static Future<void> runAppWithErrorMonitoring({
    required Future<void> Function() appRunner,
    required String sentryDsn,
    String? environment,
  }) async {
    await initialize(sentryDsn: sentryDsn, environment: environment);

    await SentryFlutter.init(
      (options) {
        options.dsn = kReleaseMode ? sentryDsn : '';
        options.environment = environment ?? (kReleaseMode ? 'production' : 'development');
      },
      appRunner: appRunner,
    );
  }
}
