import 'package:flutter/material.dart';
import 'package:frat_finance_tracker/shared/widgets/error_screen.dart';
import 'package:frat_finance_tracker/shared/services/error_monitoring_service.dart';

/// Global error handler widget that catches and displays errors
class GlobalErrorHandler extends StatelessWidget {
  final Widget child;

  const GlobalErrorHandler({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }

  /// Create an error widget for Flutter framework errors
  static Widget createErrorWidget(FlutterErrorDetails details) {
    // Report to error monitoring
    ErrorMonitoringService.captureException(
      details.exception,
      stackTrace: details.stack,
      hint: 'Flutter framework error',
      extra: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );

    // Return error screen
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ErrorScreen(
        title: 'App Error',
        message: 'The app encountered an unexpected error. Please restart the app.',
        errorCode: details.exception.runtimeType.toString(),
      ),
    );
  }
}

/// Error boundary widget for catching errors in subtrees
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }

      return ErrorScreen(
        message: 'An error occurred in this section. Please try again.',
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
      );
    }

    return widget.child;
  }

  @override
  void didUpdateWidget(ErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error when widget updates
    if (widget.child != oldWidget.child) {
      _error = null;
      _stackTrace = null;
    }
  }

  /// Catch errors from child widget
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset error on dependency changes
    _error = null;
    _stackTrace = null;
  }
}
