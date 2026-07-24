import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Responsive Helpers
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1024;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1024;

  // Colors - Dark
  static const Color bgDark = Color(0xFF1E1F21); // Warm Dark Charcoal
  static const Color cardDark = Color(0xFF28292B); // Lighter Warm Charcoal
  static const Color primaryPurple = Color(0xFFF9BA15); // Golden Honey Yellow
  static const Color primaryOrange = Color(0xFFD3A13B); // Warm Gold
  static const Color textWhite = Color(0xFFFAF9F6);
  static const Color textGrey = Color(0xFF9E9A90);

  // Colors - Light (Professional)
  static const Color softWhite = Color(0xFFFFFFFF); // Pure White for Cards
  static const Color bgLight = Color(0xFFF6F3EB); // Warm Sand Beige
  static const Color cardLight = softWhite;
  static const Color primaryIndigo = Color(0xFF28292B); // Rich Charcoal Primary
  static const Color textBlack = Color(0xFF1F1F1F); // Very Dark Charcoal (Not Pure Black)
  static const Color textLightGrey = Color(0xFF7A756C); // Warm Charcoal Grey

  // Colors - Bento UI
  static const Color bentoBg = Color(0xFFF6F3EB); // Scaffold background (Sand Beige)
  static const Color bentoJacket = Color(0xFF28292B); // Active sidebar background (Rich Charcoal)
  static const Color bentoAccent = Color(0xFFF9BA15); // Active accent/gold
  static const Color bentoSurface = softWhite; // Standard Card surfaces

  static ThemeData get darkTheme {
    final outfitFont = GoogleFonts.outfit();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryPurple,
      fontFamily: outfitFont.fontFamily,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: primaryOrange,
        surface: cardDark,
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
        displaySmall: GoogleFonts.outfit(
          color: textWhite,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: textWhite,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleLarge: GoogleFonts.outfit(
          color: textWhite,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: GoogleFonts.inter(color: textWhite, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: textWhite, fontSize: 14),
        bodySmall: GoogleFonts.inter(color: textGrey, fontSize: 12),
        labelLarge: GoogleFonts.inter(color: textWhite, fontWeight: FontWeight.w500, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textGrey.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textGrey.withValues(alpha: 0.2)),
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
          foregroundColor: const Color(0xFF28292B), // dark text on gold button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cardDark,
        contentTextStyle: GoogleFonts.inter(color: textWhite),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        insetPadding: const EdgeInsets.all(16),
      ),
    );
  }

  static ThemeData get lightTheme {
    final outfitFont = GoogleFonts.outfit();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      primaryColor: primaryIndigo,
      fontFamily: outfitFont.fontFamily,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        primary: primaryIndigo,
        secondary: primaryOrange,
        surface: cardLight,
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
        displaySmall: GoogleFonts.outfit(
          color: textBlack,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: textBlack,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleLarge: GoogleFonts.outfit(
          color: textBlack,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: GoogleFonts.inter(color: textBlack, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: textBlack, fontSize: 14),
        bodySmall: GoogleFonts.inter(color: textLightGrey, fontSize: 12),
        labelLarge: GoogleFonts.inter(color: textBlack, fontWeight: FontWeight.w500, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textLightGrey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textLightGrey.withValues(alpha: 0.3)),
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
          shadowColor: primaryIndigo.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textBlack,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        insetPadding: const EdgeInsets.all(16),
      ),
    );
  }

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, primaryOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightGradient = LinearGradient(
    colors: [primaryIndigo, Color(0xFF424447)], // Charcoal to Lighter Charcoal
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Warm Sand Background Gradient
  static const LinearGradient warmBackgroundGradient = LinearGradient(
    colors: [
      Color(0xFFF4F1EA), // Bottom-left warm beige
      Color(0xFFFFF9E6), // Top-right soft golden glow
    ],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  // Glassmorphic / Modern Card Decoration (Light)
  static BoxDecoration modernDecoration({double opacity = 1.0}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(20), // Unified 20px radius
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF5C5543).withValues(alpha: 0.06), // warm sand shadow
          blurRadius: 20,
          offset: const Offset(0, 10),
          spreadRadius: 0,
        ),
      ],
      border: Border.all(color: const Color(0xFFEBE6DD)),
    );
  }

  // Glassmorphic Decoration (Legacy Dark)
  static BoxDecoration glassDecoration({double opacity = 0.1}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(20), // Unified 20px radius
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Bento Decoration
  static BoxDecoration bentoDecoration({
    required Color color,
    double radius = 12, // Default changed to 12 for web feel
    bool shadow = false,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE5E5E5)),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ]
          : [],
    );
  }
}

