import 'package:flutter/material.dart';

class AppTheme {
  // Brand palette
  static const Color navy = Color(0xFF1E3A8A);
  static const Color gold = Color(0xFFEEAA00);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);

  // Light surfaces
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _bgLight = Color(0xFFF4F7FC);
  static const Color _borderLight = Color(0xFFE2E8F0);
  static const Color _borderStrongLight = Color(0xFFCBD5E1);
  static const Color _textPrimaryLight = Color(0xFF0F1B35);
  static const Color _textSecondaryLight = Color(0xFF64748B);

  // Dark surfaces
  static const Color _surfaceDark = Color(0xFF0D1117);
  static const Color _bgDark = Color(0xFF161C2A);
  static const Color _borderDark = Color(0xFF252D3D);
  static const Color _textPrimaryDark = Color(0xFFE8EEFF);
  static const Color _textSecondaryDark = Color(0xFF7A8EAA);

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: navy,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDEE8FF),
      onPrimaryContainer: navy,
      secondary: gold,
      onSecondary: Color(0xFF1A1100),
      secondaryContainer: Color(0xFFFFF3CD),
      onSecondaryContainer: Color(0xFF4A3600),
      tertiary: success,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFDCFCE7),
      onTertiaryContainer: Color(0xFF14532D),
      error: danger,
      onError: Colors.white,
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF7F1D1D),
      surface: _surfaceLight,
      onSurface: _textPrimaryLight,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFF8FAFD),
      surfaceContainer: _bgLight,
      surfaceContainerHigh: Color(0xFFECF0F8),
      surfaceContainerHighest: Color(0xFFE2E8F0),
      onSurfaceVariant: _textSecondaryLight,
      outline: _borderLight,
      outlineVariant: Color(0xFFF1F5F9),
      shadow: Color(0x0A1E3A8A),
      scrim: Color(0x991E3A8A),
      inverseSurface: _textPrimaryLight,
      onInverseSurface: Colors.white,
      inversePrimary: Color(0xFF93B4FF),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _bgLight,

      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _surfaceLight,
        foregroundColor: _textPrimaryLight,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: _textPrimaryLight,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: _textSecondaryLight, size: 22),
        actionsIconTheme: IconThemeData(color: _textSecondaryLight, size: 22),
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        color: _surfaceLight,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: _borderLight),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Color(0xFF94A3B8),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: const BorderSide(color: _borderStrongLight, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: _surfaceLight,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: navy,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: _borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: _borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: navy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: danger, width: 1.5),
        ),
        filled: true,
        fillColor: _surfaceLight,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: _textSecondaryLight, fontSize: 14),
        hintStyle: TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
        prefixIconColor: _textSecondaryLight,
        suffixIconColor: _textSecondaryLight,
        isDense: false,
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minVerticalPadding: 12,
        iconColor: _textSecondaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: _borderLight,
        thickness: 1,
        space: 1,
      ),

      chipTheme: const ChipThemeData(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        shape: StadiumBorder(),
        elevation: 0,
        pressElevation: 0,
        shadowColor: Colors.transparent,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surfaceLight,
        indicatorColor: const Color(0xFFDEE8FF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: navy,
              letterSpacing: 0,
            );
          }
          return const TextStyle(
            fontSize: 11,
            color: _textSecondaryLight,
            letterSpacing: 0,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: navy, size: 22);
          }
          return const IconThemeData(color: Color(0xFF94A3B8), size: 22);
        }),
      ),

      dialogTheme: const DialogThemeData(
        elevation: 8,
        backgroundColor: _surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        titleTextStyle: TextStyle(
          color: _textPrimaryLight,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: _textSecondaryLight,
          fontSize: 14,
          height: 1.5,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: _textPrimaryLight,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: _textPrimaryLight,
          fontSize: 57,
          fontWeight: FontWeight.w300,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          color: _textPrimaryLight,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: _textPrimaryLight,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          color: _textPrimaryLight,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          color: _textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          color: _textPrimaryLight,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        titleSmall: TextStyle(
          color: _textPrimaryLight,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: _textPrimaryLight,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: _textPrimaryLight,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: _textSecondaryLight,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: _textPrimaryLight,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          color: _textSecondaryLight,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        labelSmall: TextStyle(
          color: _textSecondaryLight,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkPrimary = Color(0xFF93B4FF);
    const darkGold = Color(0xFFFFD04D);

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: darkPrimary,
      onPrimary: Color(0xFF001855),
      primaryContainer: Color(0xFF1A2D5A),
      onPrimaryContainer: Color(0xFFB8CCFF),
      secondary: darkGold,
      onSecondary: Color(0xFF1A1100),
      secondaryContainer: Color(0xFF3D2E00),
      onSecondaryContainer: Color(0xFFFFE082),
      tertiary: Color(0xFF4ADE80),
      onTertiary: Color(0xFF052E16),
      tertiaryContainer: Color(0xFF052E16),
      onTertiaryContainer: Color(0xFFBBF7D0),
      error: Color(0xFFF87171),
      onError: Color(0xFF7F1D1D),
      errorContainer: Color(0xFF450A0A),
      onErrorContainer: Color(0xFFFCA5A5),
      surface: _surfaceDark,
      onSurface: _textPrimaryDark,
      surfaceContainerLowest: Color(0xFF080D14),
      surfaceContainerLow: Color(0xFF0D1320),
      surfaceContainer: _bgDark,
      surfaceContainerHigh: Color(0xFF1C2438),
      surfaceContainerHighest: Color(0xFF252D3D),
      onSurfaceVariant: _textSecondaryDark,
      outline: _borderDark,
      outlineVariant: Color(0xFF1C2435),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: _textPrimaryDark,
      onInverseSurface: _surfaceDark,
      inversePrimary: navy,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _bgDark,

      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _surfaceDark,
        foregroundColor: _textPrimaryDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: _textPrimaryDark,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: _textSecondaryDark, size: 22),
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        color: _surfaceDark,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: _borderDark),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: const Color(0xFF001855),
          disabledBackgroundColor: const Color(0xFF1C2435),
          disabledForegroundColor: _textSecondaryDark,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: const BorderSide(color: _borderDark),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),

      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: _borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: _borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: darkPrimary, width: 1.5),
        ),
        filled: true,
        fillColor: Color(0xFF0D1320),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: _textSecondaryDark, fontSize: 14),
        hintStyle: TextStyle(color: Color(0xFF3D4F65), fontSize: 14),
        prefixIconColor: _textSecondaryDark,
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minVerticalPadding: 12,
        iconColor: _textSecondaryDark,
      ),

      dividerTheme: const DividerThemeData(
        color: _borderDark,
        thickness: 1,
        space: 1,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surfaceDark,
        indicatorColor: const Color(0xFF1A2D5A),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: darkPrimary, size: 22);
          }
          return const IconThemeData(color: _textSecondaryDark, size: 22);
        }),
      ),

      dialogTheme: const DialogThemeData(
        elevation: 12,
        backgroundColor: _bgDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        titleTextStyle: TextStyle(
          color: _textPrimaryDark,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: _textSecondaryDark,
          fontSize: 14,
          height: 1.5,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF1C2438),
        contentTextStyle: const TextStyle(color: _textPrimaryDark, fontSize: 14),
      ),

      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: _textPrimaryDark,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          color: _textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: _textPrimaryDark,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: _textPrimaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: _textPrimaryDark,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: _textPrimaryDark,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: _textSecondaryDark,
          fontSize: 12,
        ),
        labelSmall: TextStyle(
          color: _textSecondaryDark,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
