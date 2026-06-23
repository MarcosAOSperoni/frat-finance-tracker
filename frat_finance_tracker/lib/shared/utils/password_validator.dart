/// Password validation utility
/// Enforces strong password requirements for security
class PasswordValidator {
  // Minimum password length
  static const int minLength = 12;

  // List of common weak passwords to reject
  static const List<String> commonPasswords = [
    'password',
    'password123',
    'Password123',
    '123456',
    '12345678',
    'qwerty',
    'abc123',
    'letmein',
    'welcome',
    'admin',
    'admin123',
  ];

  /// Validate password strength
  /// Returns null if valid, error message if invalid
  static String? validate(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    // Check minimum length
    if (password.length < minLength) {
      return 'Password must be at least $minLength characters long';
    }

    // Check for at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one digit
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Check for at least one special character
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character (!@#\$%^&*...)';
    }

    // Check against common weak passwords
    final lowerPassword = password.toLowerCase();
    for (final weakPassword in commonPasswords) {
      if (lowerPassword.contains(weakPassword.toLowerCase())) {
        return 'Password is too common. Please choose a more unique password';
      }
    }

    // Check for repeated characters (e.g., "aaaaaa")
    if (RegExp(r'(.)\1{3,}').hasMatch(password)) {
      return 'Password contains too many repeated characters';
    }

    // Check for sequential characters (e.g., "123456", "abcdef")
    if (_hasSequentialChars(password)) {
      return 'Password contains sequential characters. Please choose a more random password';
    }

    return null; // Password is valid
  }

  /// Check if password contains sequential characters
  static bool _hasSequentialChars(String password) {
    final lower = password.toLowerCase();

    // Check for numeric sequences
    for (int i = 0; i < lower.length - 3; i++) {
      final char1 = lower.codeUnitAt(i);
      final char2 = lower.codeUnitAt(i + 1);
      final char3 = lower.codeUnitAt(i + 2);
      final char4 = lower.codeUnitAt(i + 3);

      // Check if it's a sequence (ascending or descending)
      if ((char2 == char1 + 1 && char3 == char2 + 1 && char4 == char3 + 1) ||
          (char2 == char1 - 1 && char3 == char2 - 1 && char4 == char3 - 1)) {
        return true;
      }
    }

    return false;
  }

  /// Get password strength description
  static String getStrengthDescription(String password) {
    if (password.isEmpty) return '';

    int score = 0;

    // Length score
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;
    if (password.length >= 20) score++;

    // Character variety score
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;

    // Not common password
    final lowerPassword = password.toLowerCase();
    bool isCommon = commonPasswords.any(
      (weak) => lowerPassword.contains(weak.toLowerCase()),
    );
    if (!isCommon) score++;

    if (score <= 3) return 'Weak';
    if (score <= 5) return 'Fair';
    if (score <= 7) return 'Good';
    return 'Strong';
  }
}
