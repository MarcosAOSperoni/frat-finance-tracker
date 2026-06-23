import 'package:flutter/foundation.dart';

/// Secure logging utility for the application
/// Prevents sensitive data from being logged in production
class AppLogger {
  // Private constructor to prevent instantiation
  AppLogger._();

  /// Log debug information (only in debug mode)
  /// Do NOT include PII or sensitive data in messages
  static void debug(String message) {
    if (kDebugMode) {
      print('[DEBUG] $message');
    }
  }

  /// Log informational messages (only in debug mode)
  /// Do NOT include PII or sensitive data in messages
  static void info(String message) {
    if (kDebugMode) {
      print('[INFO] $message');
    }
  }

  /// Log warning messages
  /// Do NOT include PII or sensitive data in messages
  static void warning(String message) {
    if (kDebugMode) {
      print('[WARNING] $message');
    }
  }

  /// Log error messages
  /// Only log error type/category, never the full error details in production
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('[ERROR] $message');
      if (error != null) {
        print('Error details: $error');
      }
      if (stackTrace != null) {
        print('Stack trace:\n$stackTrace');
      }
    } else {
      // In production, only log generic error without details
      print('[ERROR] An error occurred: ${_sanitizeErrorMessage(message)}');
    }
  }

  /// Sanitize error messages to remove potential sensitive data
  static String _sanitizeErrorMessage(String message) {
    // Remove any potential email addresses
    String sanitized = message.replaceAll(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      '[EMAIL]',
    );

    // Remove any potential UUIDs
    sanitized = sanitized.replaceAll(
      RegExp(r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b'),
      '[ID]',
    );

    // Remove any potential numeric IDs
    sanitized = sanitized.replaceAll(
      RegExp(r'\bID:\s*[0-9a-f-]+'),
      'ID: [REDACTED]',
    );

    return sanitized;
  }

  /// Log authentication events (never log passwords or tokens)
  static void auth(String event) {
    if (kDebugMode) {
      print('[AUTH] $event');
    }
  }

  /// Log database operations (never log query results containing PII)
  static void database(String operation) {
    if (kDebugMode) {
      print('[DB] $operation');
    }
  }
}
