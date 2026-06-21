import 'package:flutter/material.dart';

abstract final class KonectaColors {
  // ── Marca principal — Cian Digital ──────────────────────────────────────
  static const Color primary = Color(0xFF06B6D4);        // Cyan-500
  static const Color primaryLight = Color(0xFF22D3EE);   // Cyan-400
  static const Color primaryDark = Color(0xFF0891B2);    // Cyan-600

  static const Color secondary = Color(0xFF0891B2);      // Cyan-600
  static const Color secondaryLight = Color(0xFF67E8F9); // Cyan-300
  static const Color secondaryDark = Color(0xFF0E7490);  // Cyan-700

  static const Color accent = Color(0xFF22D3EE);         // Cyan-400

  // ── Estados ──────────────────────────────────────────────────────────────
  static const Color online = Color(0xFF10B981);
  static const Color away = Color(0xFFF59E0B);
  static const Color offline = Color(0xFF6B7280);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);

  // ── Burbujas de chat ─────────────────────────────────────────────────────
  static const Color bubbleSentDark = Color(0xFF013340);    // Cian oscuro profundo
  static const Color bubbleReceivedDark = Color(0xFF0A1A1E);
  static const Color bubbleSentLight = Color(0xFF06B6D4);   // Cian primario
  static const Color bubbleReceivedLight = Color(0xFFE0F9FC);

  // ── Modo OSCURO ───────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF020B0E);  // Casi negro con tono cian
  static const Color darkSurface = Color(0xFF05141A);
  static const Color darkSurface2 = Color(0xFF071E27);
  static const Color darkSurface3 = Color(0xFF0A2733);
  static const Color darkSurface4 = Color(0xFF0D3040);

  // Texto dark mode — WCAG AA/AAA compliant sobre #020B0E
  static const Color darkTextPrimary = Color(0xFFE0F9FC);    // ~18:1 contrast
  static const Color darkTextSecondary = Color(0xFFA8D8E0);  // ~8:1 contrast ✓
  static const Color darkTextTertiary = Color(0xFF537A80);   // ~4.5:1 contrast ✓

  static const Color darkDivider = Color(0xFF0A2733);
  static const Color darkBorder = Color(0xFF163D4A);

  // ── Modo CLARO ────────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFE0F9FC);   // Cyan-50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFCFFAFE);     // Cyan-100
  static const Color lightSurface3 = Color(0xFFA5F3FC);     // Cyan-200
  static const Color lightSurface4 = Color(0xFF67E8F9);     // Cyan-300

  static const Color lightTextPrimary = Color(0xFF0A2733);   // Casi negro con tono cian
  static const Color lightTextSecondary = Color(0xFF374151); // Gris oscuro
  static const Color lightTextTertiary = Color(0xFF6B7280);  // Gris medio

  static const Color lightDivider = Color(0xFFCFFAFE);
  static const Color lightBorder = Color(0xFFA5F3FC);
}
