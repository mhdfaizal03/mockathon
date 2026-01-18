import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors - Dark
  static const Color bgDark = Color(0xFF0F172A); // Dark Slate Blue
  static const Color cardDark = Color(0xFF1E293B); // Lighter Slate
  static const Color primaryPurple = Color(0xFF6366F1); // Indigo 500
  static const Color primaryOrange = Color(0xFFF97316);
  static const Color textWhite = Color(0xFFF8FAFC);
  static const Color textGrey = Color(0xFF94A3B8);

  // Colors - Light (Professional)
  static const Color softWhite = Color(0xFFF9FAFB); // Soft Off-White
  static const Color bgLight = Color(0xFFF1F5F9); // Slightly Darker Slate
  static const Color cardLight = softWhite;
  static const Color primaryIndigo = Color(0xFF4338CA); // Indigo 700
  static const Color textBlack = Color(0xFF1E293B); // Slate 800
  static const Color textLightGrey = Color(0xFF64748B); // Slate 500

  // Colors - Bento UI
  static const Color bentoBg = Color(
    0xFFE2E8F0,
  ); // Darker Grey/Slate Background
  static const Color bentoJacket = Color(
    0xFF3A4155,
  ); // Dark Slate (Weather Card)
  static const Color bentoAccent = Color(
    0xFFDAC09B,
  ); // Beige/Wheat (Temperature Card)
  static const Color bentoSurface = softWhite; // Standard Cards

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryPurple,
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: primaryOrange,
        surface: cardDark,
        background: bgDark,
        onBackground: textWhite,
        onSurface: textWhite,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          color: textWhite,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        displayMedium: GoogleFonts.outfit(
          color: textWhite,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        bodyLarge: GoogleFonts.inter(color: textWhite, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: textGrey, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textGrey.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textGrey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPurple),
        ),
        labelStyle: GoogleFonts.inter(color: textGrey),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      primaryColor: primaryIndigo,
      colorScheme: const ColorScheme.light(
        primary: primaryIndigo,
        secondary: primaryOrange,
        surface: cardLight,
        background: bgLight,
        onBackground: textBlack,
        onSurface: textBlack,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textBlack),
        titleTextStyle: TextStyle(
          color: textBlack,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          color: textBlack,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        displayMedium: GoogleFonts.outfit(
          color: textBlack,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        bodyLarge: GoogleFonts.inter(color: textBlack, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: textLightGrey, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textLightGrey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textLightGrey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryIndigo, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: textLightGrey),
        floatingLabelStyle: GoogleFonts.inter(color: primaryIndigo),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryIndigo,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryIndigo.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // Linear Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, primaryOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightGradient = LinearGradient(
    colors: [primaryIndigo, Color(0xFF6366F1)], // Indigo 700 to Indigo 500
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphic / Modern Card Decoration (Light)
  static BoxDecoration modernDecoration({double opacity = 1.0}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF64748B).withOpacity(0.1), // Slate shadow
          blurRadius: 20,
          offset: const Offset(0, 10),
          spreadRadius: 0,
        ),
      ],
      border: Border.all(color: Colors.white),
    );
  }

  // Glassmorphic Decoration (Legacy Dark)
  static BoxDecoration glassDecoration({double opacity = 0.1}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Bento Decoration
  static BoxDecoration bentoDecoration({
    required Color color,
    double radius = 32,
    bool shadow = false,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.black.withOpacity(0.05)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        if (shadow)
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
      ],
    );
  }
}
