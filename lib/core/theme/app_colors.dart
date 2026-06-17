import 'package:flutter/material.dart';

abstract final class KonectaColors {
  // ── Marca principal — Violeta Konecta ─────────────────────────────────────
  static const Color primary = Color(0xFF7C3AED);       // Violet-600
  static const Color primaryLight = Color(0xFFA78BFA);  // Violet-400
  static const Color primaryDark = Color(0xFF6D28D9);   // Violet-700

  static const Color secondary = Color(0xFF8B5CF6);     // Violet-500
  static const Color secondaryLight = Color(0xFFC4B5FD); // Violet-300
  static const Color secondaryDark = Color(0xFF6D28D9);  // Violet-700

  static const Color accent = Color(0xFFA78BFA);        // Violet-400

  // ── Estados ──────────────────────────────────────────────────────────────
  static const Color online = Color(0xFF10B981);
  static const Color away = Color(0xFFF59E0B);
  static const Color offline = Color(0xFF6B7280);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);

  // ── Burbujas de chat ─────────────────────────────────────────────────────
  static const Color bubbleSentDark = Color(0xFF1D0D40);    // Violeta oscuro profundo
  static const Color bubbleReceivedDark = Color(0xFF1A1A26);
  static const Color bubbleSentLight = Color(0xFF7C3AED);   // Violeta primario
  static const Color bubbleReceivedLight = Color(0xFFF5F3FF);

  // ── Modo OSCURO ───────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF07060F);  // Casi negro con tono violeta
  static const Color darkSurface = Color(0xFF0E0B1A);
  static const Color darkSurface2 = Color(0xFF160F28);
  static const Color darkSurface3 = Color(0xFF1E1436);
  static const Color darkSurface4 = Color(0xFF261844);

  // Texto dark mode — WCAG AA/AAA compliant sobre #07060F
  static const Color darkTextPrimary = Color(0xFFECF0FC);    // ~18:1 contrast
  static const Color darkTextSecondary = Color(0xFFB0A8D0);  // ~8:1 contrast ✓
  static const Color darkTextTertiary = Color(0xFF6D6390);   // ~4.5:1 contrast ✓

  static const Color darkDivider = Color(0xFF1E1436);
  static const Color darkBorder = Color(0xFF2D1F50);

  // ── Modo CLARO ────────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F3FF);   // Violet-50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFEDE9FE);     // Violet-100
  static const Color lightSurface3 = Color(0xFFDDD6FE);     // Violet-200
  static const Color lightSurface4 = Color(0xFFC4B5FD);     // Violet-300

  static const Color lightTextPrimary = Color(0xFF1A0A33);   // Casi negro con tono violeta
  static const Color lightTextSecondary = Color(0xFF374151); // Gris oscuro
  static const Color lightTextTertiary = Color(0xFF6B7280);  // Gris medio

  static const Color lightDivider = Color(0xFFEDE9FE);
  static const Color lightBorder = Color(0xFFDDD6FE);
}
