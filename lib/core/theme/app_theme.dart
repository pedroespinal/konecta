import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark => _buildTheme(Brightness.dark);
  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? KonectaColors.darkBackground : KonectaColors.lightBackground;
    final surface = isDark ? KonectaColors.darkSurface : KonectaColors.lightSurface;
    final surface2 = isDark ? KonectaColors.darkSurface2 : KonectaColors.lightSurface2;
    final textPrimary = isDark ? KonectaColors.darkTextPrimary : KonectaColors.lightTextPrimary;
    final textSecondary = isDark ? KonectaColors.darkTextSecondary : KonectaColors.lightTextSecondary;
    final divider = isDark ? KonectaColors.darkDivider : KonectaColors.lightDivider;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: KonectaColors.primary,
      onPrimary: Colors.white,
      primaryContainer: isDark ? KonectaColors.darkSurface3 : KonectaColors.lightSurface3,
      onPrimaryContainer: textPrimary,
      secondary: KonectaColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: isDark ? KonectaColors.darkSurface2 : KonectaColors.lightSurface2,
      onSecondaryContainer: textPrimary,
      tertiary: KonectaColors.accent,
      onTertiary: Colors.white,
      tertiaryContainer: isDark ? KonectaColors.darkSurface3 : KonectaColors.lightSurface3,
      onTertiaryContainer: textPrimary,
      error: KonectaColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFF7F1D1D),
      onErrorContainer: const Color(0xFFFECACA),
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: surface2,
      onSurfaceVariant: textSecondary,
      outline: divider,
      outlineVariant: isDark ? KonectaColors.darkBorder : KonectaColors.lightBorder,
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: isDark ? KonectaColors.lightSurface : KonectaColors.darkSurface,
      onInverseSurface: isDark ? KonectaColors.lightTextPrimary : KonectaColors.darkTextPrimary,
      inversePrimary: KonectaColors.primaryLight,
    );

    final textTheme = GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        displaySmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 16),
        titleSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14, height: 1.5),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12, height: 1.4),
        labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
        labelMedium: TextStyle(color: textSecondary, fontWeight: FontWeight.w500, fontSize: 12),
        labelSmall: TextStyle(color: textSecondary, fontWeight: FontWeight.w500, fontSize: 11),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      dividerTheme: DividerThemeData(color: divider, thickness: 0.5, space: 0),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: divider,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: KonectaColors.primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: KonectaColors.primary.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: KonectaColors.primary, size: 24);
          }
          return IconThemeData(color: textSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: KonectaColors.primary,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textSecondary,
          );
        }),
        elevation: 0,
        height: 64,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: divider, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: KonectaColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: textSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KonectaColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KonectaColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: KonectaColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: textSecondary,
        ),
        iconColor: textSecondary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return KonectaColors.primary;
          return isDark ? KonectaColors.darkTextTertiary : KonectaColors.lightTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return KonectaColors.primary.withValues(alpha: 0.4);
          }
          return isDark ? KonectaColors.darkSurface3 : KonectaColors.lightSurface3;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface2,
        selectedColor: KonectaColors.primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(fontSize: 13, color: textPrimary),
        side: BorderSide(color: divider, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? KonectaColors.darkSurface3 : KonectaColors.darkSurface2,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: textSecondary),
      ),
    );
  }
}
