import 'package:flutter/material.dart';

/// Central theme colors and styling tokens matching the DineQueue Admin design
class AdminTheme {
  // Brand & Accent Colors
  static const Color primaryDark = Color(0xFF0A3B2B);
  static const Color headerGreen = Color(0xFF074332);
  static const Color headerTextMint = Color(0xFF90CBB5);
  static const Color primaryDarkHover = Color(0xFF072C20);
  static const Color accentOrange = Color(0xFFF05336);
  static const Color accentOrangeDark = Color(0xFFD63E23);
  static const Color brandGreen = Color(0xFF094E38);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF7FAF8);
  static const Color cardBg = Colors.white;
  static const Color surfaceMuted = Color(0xFFF2F6F4);
  static const Color cancelBtnBg = Color(0xFFF0F4F2);
  static const Color borderSubtle = Color(0xFFE4EDE7);
  static const Color inputBorder = Color(0xFFD5E3DC);

  // Status Badge Colors
  static const Color badgeGreenBg = Color(0xFFD6F5E3);
  static const Color badgeGreenText = Color(0xFF0B7846);

  static const Color badgeOrangeBg = Color(0xFFFFEBE1);
  static const Color badgeOrangeText = Color(0xFFDE5523);

  static const Color badgeYellowBg = Color(0xFFFFF2D6);
  static const Color badgeYellowText = Color(0xFFB57400);

  static const Color badgeGreyBg = Color(0xFFEDF2EE);
  static const Color badgeGreyText = Color(0xFF6A7F75);

  // Text Colors
  static const Color textDark = Color(0xFF0C3829);
  static const Color textSecondary = Color(0xFF6D8479);
  static const Color textMuted = Color(0xFF90A39A);

  // Text Styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: textDark,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textDark,
    letterSpacing: -0.3,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: textDark,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 13,
    color: textSecondary,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  // Decoration Helpers
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderSubtle, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static InputDecoration inputDecoration({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      labelText: labelText,
      labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: inputBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryDark, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentOrange, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentOrange, width: 1.5),
      ),
    );
  }
}
