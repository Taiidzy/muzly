import 'package:flutter/material.dart';

/// App Theme constants based on player.html design
/// 
/// Color scheme and styling inspired by the minimal, dark aesthetic
/// with Japanese night theme elements
class AppTheme {
  // Base colors from player.html
  static const Color bg = Color(0xFF0C0D10);
  static const Color surface = Color(0xFF111318);
  static const Color border = Color(0x0FFFFFFF); // 6% opacity
  static const Color text = Color(0xFFC8CDD6);
  static const Color textDim = Color(0xFF4A5060);
  static const Color textMuted = Color(0xFF2E333D);
  static const Color accent = Color(0xFF7A8FA6);
  static const Color liked = Color(0xFFAF7387); // Pink-ish for liked tracks

  // Additional colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  // Gradients for backgrounds
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0C0D10),
      Color(0xFF0A0B0E),
    ],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF141820),
      Color(0xFF0E1116),
    ],
  );

  /// Border with proper opacity
  static Border borderLine = Border.all(
    color: border,
    width: 1,
  );

  /// Dark theme data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: accent,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: surface,
        error: Color(0xFFCF6679),
        onPrimary: text,
        onSecondary: text,
        onSurface: text,
        onError: white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inconsolata',
          fontSize: 16,
          letterSpacing: 2,
          color: text,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'IM Fell English',
          fontSize: 32,
          color: text,
        ),
        displayMedium: TextStyle(
          fontFamily: 'IM Fell English',
          fontSize: 28,
          color: text,
        ),
        displaySmall: TextStyle(
          fontFamily: 'IM Fell English',
          fontSize: 24,
          color: text,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Noto Serif JP',
          fontSize: 18,
          color: text,
        ),
        titleLarge: TextStyle(
          fontFamily: 'IM Fell English',
          fontSize: 21,
          letterSpacing: 0.3,
          color: text,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inconsolata',
          fontSize: 14,
          letterSpacing: 2,
          color: text,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Inconsolata',
          fontSize: 10,
          letterSpacing: 2,
          color: textDim,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inconsolata',
          fontSize: 14,
          color: text,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inconsolata',
          fontSize: 12,
          color: textDim,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Inconsolata',
          fontSize: 12,
          letterSpacing: 1.5,
          color: text,
        ),
      ),
      iconTheme: const IconThemeData(
        color: textDim,
        size: 20,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: textMuted,
        thumbColor: text,
        overlayColor: accent.withAlpha(77),
        trackHeight: 1,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 3.5),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textDim,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide(
            color: border,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide(
            color: border,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: accent, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
